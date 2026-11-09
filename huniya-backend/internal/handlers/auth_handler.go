package handlers

import (
	"net/http"

	"huniya-backend/internal/dto"
	"huniya-backend/internal/services"
	"huniya-backend/pkg/utils"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService services.AuthService
}

func NewAuthHandler(authService services.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Data registrasi tidak valid: "+err.Error())
		return
	}

	res, err := h.authService.Register(req)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.SendSuccess(c, http.StatusCreated, "Registrasi berhasil", res, nil)
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Format email atau password tidak valid")
		return
	}

	res, err := h.authService.Login(req)
	if err != nil {
		utils.SendError(c, http.StatusUnauthorized, err.Error())
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Login berhasil", res, nil)
}

func (h *AuthHandler) Me(c *gin.Context) {
	userID := c.GetUint("user_id")
	res, err := h.authService.GetCurrentUser(userID)
	if err != nil {
		utils.SendError(c, http.StatusNotFound, err.Error())
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil profil pengguna", res, nil)
}
