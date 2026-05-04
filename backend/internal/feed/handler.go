package feed

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/toktak/backend/internal/database"
)

type Handler struct {
	store *database.Store
}

func NewHandler(s *database.Store) *Handler {
	return &Handler{store: s}
}

func (h *Handler) GetFeed(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 50 {
		limit = 10
	}
	offset := (page - 1) * limit

	videos, err := h.store.GetFeedVideos(c.Request.Context(), limit, offset, h.currentUserID(c))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"videos":   videos,
		"has_more": len(videos) == limit,
		"page":     page,
	})
}

func (h *Handler) currentUserID(c *gin.Context) string {
	v, _ := c.Get("userID")
	s, _ := v.(string)
	return s
}
