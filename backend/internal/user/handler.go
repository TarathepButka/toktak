package user

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

func (h *Handler) GetUser(c *gin.Context) {
	user, err := h.store.GetUserByID(c.Request.Context(), c.Param("id"))
	if err != nil || user == nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "user not found"})
		return
	}
	c.JSON(http.StatusOK, user)
}

func (h *Handler) GetUserVideos(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}

	videos, err := h.store.GetUserVideos(c.Request.Context(), c.Param("id"), h.currentUserID(c), limit, (page-1)*limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"videos": videos, "page": page})
}

func (h *Handler) currentUserID(c *gin.Context) string {
	v, _ := c.Get("userID")
	s, _ := v.(string)
	return s
}
