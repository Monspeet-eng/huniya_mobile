package handlers

import (
	"net/http"

	"huniya-backend/internal/dto"
	"huniya-backend/internal/services"
	"huniya-backend/pkg/utils"

	"github.com/gin-gonic/gin"
)

type WalletHandler struct {
	walletService services.WalletService
}

func NewWalletHandler(walletService services.WalletService) *WalletHandler {
	return &WalletHandler{walletService: walletService}
}

func (h *WalletHandler) GetWallet(c *gin.Context) {
	userID := c.GetUint("user_id")
	wallet, err := h.walletService.GetWallet(userID)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal mengambil data wallet: "+err.Error())
		return
	}
	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil data wallet", wallet, nil)
}

func (h *WalletHandler) TopUp(c *gin.Context) {
	userID := c.GetUint("user_id")
	var req dto.TopUpRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Nominal top-up tidak valid: "+err.Error())
		return
	}

	tx, err := h.walletService.TopUp(userID, req.Amount)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal melakukan top-up: "+err.Error())
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Top-up saldo berhasil", tx, nil)
}

func (h *WalletHandler) GetTransactions(c *gin.Context) {
	userID := c.GetUint("user_id")
	transactions, err := h.walletService.GetTransactions(userID)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal mengambil riwayat transaksi: "+err.Error())
		return
	}
	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil riwayat transaksi", transactions, nil)
}
