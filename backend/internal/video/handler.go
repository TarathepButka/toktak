package video

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toktak/backend/internal/database"
	"github.com/toktak/backend/internal/storage"
)

type Handler struct {
	store *database.Store
	minio *storage.MinIOClient
}

func NewHandler(s *database.Store, m *storage.MinIOClient) *Handler {
	return &Handler{
		store: s,
		minio: m,
	}
}

// ─── Video Handlers ───────────────────────────────────────────

func (h *Handler) GetVideo(c *gin.Context) {
	video, err := h.store.GetVideoByID(c.Request.Context(), c.Param("id"), h.currentUserID(c))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "video not found"})
		return
	}
	c.JSON(http.StatusOK, video)
}

func (h *Handler) UploadVideo(c *gin.Context) {
	userID := h.currentUserID(c)
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 500<<20)

	if err := c.Request.ParseMultipartForm(32 << 20); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "failed to parse upload: " + err.Error()})
		return
	}

	file, header, err := c.Request.FormFile("video")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "video file required"})
		return
	}
	defer file.Close()

	if h.minio == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"message": "storage not configured"})
		return
	}

	caption := c.Request.FormValue("caption")
	objectName := fmt.Sprintf("%s/%d_%s", userID, time.Now().UnixMilli(), header.Filename)
	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "video/mp4"
	}

	videoURL, err := h.minio.Upload(c.Request.Context(), objectName, contentType, file, header.Size)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "storage upload failed: " + err.Error()})
		return
	}

	thumbnailURL := fmt.Sprintf("https://picsum.photos/seed/%d/400/700", time.Now().UnixMilli()%1000)

	video, err := h.store.CreateVideo(c.Request.Context(), database.CreateVideoInput{
		UserID:       userID,
		VideoURL:     videoURL,
		ThumbnailURL: thumbnailURL,
		Caption:      caption,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, video)
}

func (h *Handler) LikeVideo(c *gin.Context) {
	userID := h.currentUserID(c)
	videoID := c.Param("id")

	if err := h.store.LikeVideo(c.Request.Context(), userID, videoID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	video, _ := h.store.GetVideoByID(c.Request.Context(), videoID, userID)
	c.JSON(http.StatusOK, video)
}

func (h *Handler) UnlikeVideo(c *gin.Context) {
	userID := h.currentUserID(c)
	videoID := c.Param("id")

	if err := h.store.UnlikeVideo(c.Request.Context(), userID, videoID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	video, _ := h.store.GetVideoByID(c.Request.Context(), videoID, userID)
	c.JSON(http.StatusOK, video)
}

func (h *Handler) Search(c *gin.Context) {
	keyword := c.Query("q")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	
	videos, err := h.store.SearchVideos(c.Request.Context(), keyword, h.currentUserID(c), limit, (page-1)*limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"results": videos, "page": page})
}

func (h *Handler) Trending(c *gin.Context) {
	videos, err := h.store.SearchVideos(c.Request.Context(), "", h.currentUserID(c), 20, 0)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"trending": videos})
}

func (h *Handler) PresignUpload(c *gin.Context) {
	if h.minio == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"message": "storage not configured"})
		return
	}

	var payload struct {
		Filename    string `json:"filename"`
		ContentType string `json:"content_type"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil || payload.Filename == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "filename required"})
		return
	}
	if payload.ContentType == "" {
		payload.ContentType = "video/mp4"
	}

	objectName := fmt.Sprintf("%s/%d_%s", h.currentUserID(c), time.Now().UnixMilli(), payload.Filename)

	presignURL, err := h.minio.PresignUpload(c.Request.Context(), objectName, payload.ContentType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"upload_url":  presignURL.String(),
		"object_name": objectName,
		"public_url":  h.minio.PublicURL(objectName),
	})
}

// ─── Helpers ─────────────────────────────────────────────────

func (h *Handler) currentUserID(c *gin.Context) string {
	v, _ := c.Get("userID")
	s, _ := v.(string)
	return s
}
