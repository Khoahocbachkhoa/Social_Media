package handler

import (
	"errors"
	"net/http"

	"webapp/internal/dto"
	"webapp/internal/service"
	"webapp/pkg/response"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService *service.AuthService
}

func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Dữ liệu đăng ký không hợp lệ!")
		return
	}

	res, err := h.authService.Register(c.Request.Context(), req)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrEmailExists):
			response.Error(c, http.StatusConflict, "email đã tồn tại")
		case errors.Is(err, service.ErrUsernameExists):
			response.Error(c, http.StatusConflict, "username đã tồn tại")
		default:
			response.Error(c, http.StatusInternalServerError, "không thể đăng ký")
		}
		return
	}

	c.JSON(http.StatusCreated, res)
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "dữ liệu đăng nhập không hợp lệ")
		return
	}

	res, err := h.authService.Login(c.Request.Context(), req)
	if err != nil {
		if errors.Is(err, service.ErrInvalidCredentials) {
			response.Error(c, http.StatusUnauthorized, "tài khoản hoặc mật khẩu không đúng")
			return
		}
		response.Error(c, http.StatusInternalServerError, "không thể đăng nhập")
		return
	}

	c.JSON(http.StatusOK, res)
}

func (h *AuthHandler) Me(c *gin.Context) {
	userID, _ := c.Get("user_id")
	username, _ := c.Get("username")
	c.JSON(http.StatusOK, gin.H{
		"user": gin.H{
			"id":       userID,
			"username": username,
		},
	})
}
