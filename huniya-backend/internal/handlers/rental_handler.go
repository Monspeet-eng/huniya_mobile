package handlers

import (
	"net/http"
	"strconv"

	"huniya-backend/internal/dto"
	"huniya-backend/internal/services"
	"huniya-backend/pkg/utils"

	"github.com/gin-gonic/gin"
)

type RentalHandler struct {
	rentalService services.RentalService
}

func NewRentalHandler(rentalService services.RentalService) *RentalHandler {
	return &RentalHandler{rentalService: rentalService}
}

func (h *RentalHandler) CreateRental(c *gin.Context) {
	tenantID := c.GetUint("user_id")
	var req dto.CreateRentalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Data booking/sewa tidak valid: "+err.Error())
		return
	}

	rental, err := h.rentalService.CreateRental(tenantID, req.PropertyID, req.MonthsCount)
	if err != nil {
		status := http.StatusInternalServerError
		if err == services.ErrInsufficientBalance {
			status = http.StatusBadRequest
		}
		utils.SendError(c, status, "Gagal memulai sewa: "+err.Error())
		return
	}

	utils.SendSuccess(c, http.StatusCreated, "Pembayaran sewa awal berhasil diproses", rental, nil)
}

func (h *RentalHandler) PayRent(c *gin.Context) {
	tenantID := c.GetUint("user_id")
	rentalIDStr := c.Param("id")
	rentalID, err := strconv.ParseUint(rentalIDStr, 10, 64)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "ID sewa tidak valid")
		return
	}

	var req dto.PayRentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Jumlah bulan tidak valid: "+err.Error())
		return
	}

	payment, err := h.rentalService.PayRent(tenantID, uint(rentalID), req.MonthsCount)
	if err != nil {
		status := http.StatusInternalServerError
		if err == services.ErrInsufficientBalance || err == services.ErrForbiddenAccess {
			status = http.StatusBadRequest
		}
		utils.SendError(c, status, "Gagal membayar perpanjangan sewa: "+err.Error())
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Pembayaran sewa multi-bulan berhasil diproses", payment, nil)
}

func (h *RentalHandler) GetUserRentals(c *gin.Context) {
	tenantID := c.GetUint("user_id")
	rentals, err := h.rentalService.GetUserRentals(tenantID)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal mengambil daftar sewa: "+err.Error())
		return
	}
	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil data sewa pengguna", rentals, nil)
}

func (h *RentalHandler) GetOwnerRentals(c *gin.Context) {
	ownerID := c.GetUint("user_id")
	rentals, err := h.rentalService.GetOwnerRentals(ownerID)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal mengambil data sewa properti Anda: "+err.Error())
		return
	}
	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil data sewa owner", rentals, nil)
}

func (h *RentalHandler) GetDueReminders(c *gin.Context) {
	tenantID := c.GetUint("user_id")
	reminders, err := h.rentalService.GetDueReminders(tenantID)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal mengambil pengingat sewa: "+err.Error())
		return
	}
	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil pengingat jatuh tempo sewa", reminders, nil)
}
