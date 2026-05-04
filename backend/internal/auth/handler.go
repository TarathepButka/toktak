package auth

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) GoogleAuth(c *gin.Context) {
	var payload struct {
		IDToken string `json:"id_token"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil && !strings.Contains(err.Error(), "EOF") {
		c.JSON(http.StatusBadRequest, gin.H{"message": "invalid request payload"})
		return
	}
	if payload.IDToken == "" {
		payload.IDToken = c.PostForm("id_token")
	}
	if payload.IDToken == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "id_token required"})
		return
	}
	response, err := h.svc.LoginWithGoogle(c.Request.Context(), payload.IDToken)
	if err != nil {
		h.respondAuthError(c, err)
		return
	}
	c.JSON(http.StatusOK, response)
}

func (h *Handler) LineAuth(c *gin.Context) {
	var payload struct {
		AccessToken string `json:"access_token"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil && !strings.Contains(err.Error(), "EOF") {
		c.JSON(http.StatusBadRequest, gin.H{"message": "invalid request payload"})
		return
	}
	if payload.AccessToken == "" {
		payload.AccessToken = c.PostForm("access_token")
	}
	if payload.AccessToken == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "access_token required"})
		return
	}
	response, err := h.svc.LoginWithLine(c.Request.Context(), payload.AccessToken)
	if err != nil {
		h.respondAuthError(c, err)
		return
	}
	c.JSON(http.StatusOK, response)
}

func (h *Handler) RefreshToken(c *gin.Context) {
	var payload struct {
		RefreshToken string `json:"refresh_token"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil && !strings.Contains(err.Error(), "EOF") {
		c.JSON(http.StatusBadRequest, gin.H{"message": "invalid request payload"})
		return
	}
	if payload.RefreshToken == "" {
		payload.RefreshToken = c.PostForm("refresh_token")
	}
	response, err := h.svc.RefreshSession(c.Request.Context(), payload.RefreshToken)
	if err != nil {
		h.respondAuthError(c, err)
		return
	}
	c.JSON(http.StatusOK, response)
}

func (h *Handler) respondAuthError(c *gin.Context, err error) {
	message := err.Error()
	status := http.StatusInternalServerError
	switch {
	case strings.Contains(message, "missing"):
		status = http.StatusBadRequest
	case strings.Contains(message, "invalid"), strings.Contains(message, "mismatch"),
		strings.Contains(message, "verification failed"), strings.Contains(message, "no rows"),
		strings.Contains(message, "expired"):
		status = http.StatusUnauthorized
	}
	c.JSON(status, gin.H{"message": message})
}
