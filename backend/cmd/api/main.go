package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/toktak/backend/internal/auth"
	dbstore "github.com/toktak/backend/internal/database"
	"github.com/toktak/backend/internal/feed"
	"github.com/toktak/backend/internal/storage"
	"github.com/toktak/backend/internal/user"
	"github.com/toktak/backend/internal/video"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("[INFO] No .env file found, using system env")
	}

	// 1. Setup Infrastructure
	store, err := dbstore.NewStore(os.Getenv("TOKTAK_DB_PATH"))
	if err != nil {
		log.Fatal(err)
	}
	defer store.Close() //nolint:errcheck

	if err := store.MigrateVideoSchema(context.Background()); err != nil {
		log.Fatalf("migrate video schema: %v", err)
	}

	minioClient, err := storage.NewMinIOClient()
	if err != nil {
		log.Printf("[WARNING] MinIO unavailable: %v", err)
	}

	// 2. Setup Services & Handlers
	authSvc := auth.NewService(store, os.Getenv("GOOGLE_CLIENT_ID"), os.Getenv("LINE_CHANNEL_ID"))
	
	authHandler := auth.NewHandler(authSvc)
	videoHandler := video.NewHandler(store, minioClient)
	feedHandler := feed.NewHandler(store)
	userHandler := user.NewHandler(store)

	// 3. Setup Router
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// Public Auth
	authGroup := r.Group("/auth")
	{
		authGroup.POST("/google", authHandler.GoogleAuth)
		authGroup.POST("/line", authHandler.LineAuth)
		authGroup.POST("/refresh", authHandler.RefreshToken)
	}

	// Public Content
	r.GET("/feed", optionalAuth(store), feedHandler.GetFeed)
	r.GET("/search", optionalAuth(store), videoHandler.Search)
	r.GET("/search/trending", optionalAuth(store), videoHandler.Trending)

	// Protected Routes
	api := r.Group("", requireAuth(store))
	{
		videos := api.Group("/videos")
		{
			videos.GET("/:id", videoHandler.GetVideo)
			videos.POST("", videoHandler.UploadVideo)
			videos.POST("/:id/like", videoHandler.LikeVideo)
			videos.DELETE("/:id/like", videoHandler.UnlikeVideo)
			
			// Placeholders for comments
			videos.GET("/:id/comments", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"comments": []any{}}) })
			videos.POST("/:id/comments", func(c *gin.Context) { c.JSON(http.StatusCreated, gin.H{"message": "comment added"}) })
		}

		users := api.Group("/users")
		{
			users.GET("/:id", userHandler.GetUser)
			users.GET("/:id/videos", userHandler.GetUserVideos)
		}

		api.POST("/upload/presign", videoHandler.PresignUpload)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("🚀 TokTak API started on :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// ─── Auth Middlewares ────────────────────────────────────────

func requireAuth(s *dbstore.Store) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, err := extractUserID(c, s)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"message": "unauthorized"})
			return
		}
		c.Set("userID", userID)
		c.Next()
	}
}

func optionalAuth(s *dbstore.Store) gin.HandlerFunc {
	return func(c *gin.Context) {
		if userID, err := extractUserID(c, s); err == nil {
			c.Set("userID", userID)
		}
		c.Next()
	}
}

func extractUserID(c *gin.Context, s *dbstore.Store) (string, error) {
	header := c.GetHeader("Authorization")
	if !strings.HasPrefix(header, "Bearer ") {
		return "", fmt.Errorf("no bearer token")
	}
	token := strings.TrimPrefix(header, "Bearer ")
	return s.GetUserIDByAccessToken(c.Request.Context(), token)
}
