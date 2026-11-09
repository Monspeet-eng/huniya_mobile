package handlers

import (
	"net/http"
	"strconv"

	"huniya-backend/internal/dto"
	"huniya-backend/internal/services"
	"huniya-backend/pkg/utils"

	"github.com/gin-gonic/gin"
)

type BoostHandler struct {
	boostService services.BoostService
}

func NewBoostHandler(boostService services.BoostService) *BoostHandler {
	return &BoostHandler{boostService: boostService}
}

func (h *BoostHandler) PurchaseBoost(c *gin.Context) {
	ownerID := c.GetUint("user_id")
	propIDStr := c.Param("id")
	propID, err := strconv.ParseUint(propIDStr, 10, 64)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "ID properti tidak valid")
		return
	}

	var req dto.PurchaseBoostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Durasi bulan boost tidak valid: "+err.Error())
		return
	}

	boost, err := h.boostService.PurchaseBoost(ownerID, uint(propID), req.MonthsCount)
	if err != nil {
		status := http.StatusInternalServerError
		if err == services.ErrInsufficientBalance || err == services.ErrForbiddenAccess {
			status = http.StatusBadRequest
		}
		utils.SendError(c, status, "Gagal melakukan boost iklan: "+err.Error())
		return
	}

	utils.SendSuccess(c, http.StatusCreated, "Boost iklan kos berhasil diaktifkan", boost, nil)
}

func (h *BoostHandler) GetPropertyBoost(c *gin.Context) {
	ownerID := c.GetUint("user_id")
	propIDStr := c.Param("id")
	propID, err := strconv.ParseUint(propIDStr, 10, 64)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "ID properti tidak valid")
		return
	}

	boost, err := h.boostService.GetPropertyBoost(ownerID, uint(propID))
	if err != nil {
		utils.SendError(c, http.StatusNotFound, "Tidak ada boost iklan aktif untuk properti ini")
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil status boost iklan", boost, nil)
}

func (h *BoostHandler) GetBoostedRecommendations(c *gin.Context) {
	props, err := h.boostService.GetBoostedProperties()
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal mengambil rekomendasi kos sponsor: "+err.Error())
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil kos rekomendasi sponsor", props, nil)
}
