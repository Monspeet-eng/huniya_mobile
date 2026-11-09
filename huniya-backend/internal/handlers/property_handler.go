package handlers

import (
	"errors"
	"mime/multipart"
	"net/http"
	"strconv"

	"huniya-backend/internal/dto"
	"huniya-backend/internal/services"
	"huniya-backend/pkg/storage"
	"huniya-backend/pkg/utils"

	"github.com/gin-gonic/gin"
)

type PropertyHandler struct {
	propService services.PropertyService
}

func NewPropertyHandler(propService services.PropertyService) *PropertyHandler {
	return &PropertyHandler{propService: propService}
}

func (h *PropertyHandler) GetProperties(c *gin.Context) {
	var query dto.PropertyFilterQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Parameter pencarian tidak valid: "+err.Error())
		return
	}

	props, total, err := h.propService.GetProperties(query)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal mengambil daftar properti")
		return
	}

	meta := &utils.Meta{
		Page:  query.Page,
		Limit: query.Limit,
		Total: total,
	}
	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil data properti", props, meta)
}

func (h *PropertyHandler) GetNearbyProperties(c *gin.Context) {
	var query dto.NearbyQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Koordinat GPS (lat & lng) wajib diisi")
		return
	}

	props, err := h.propService.GetNearbyProperties(query)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal mencari properti terdekat")
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil properti terdekat", props, nil)
}

func (h *PropertyHandler) GetPropertyDetail(c *gin.Context) {
	id, err := parseIDParam(c, "id")
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "ID properti tidak valid")
		return
	}

	prop, err := h.propService.GetPropertyByID(id)
	if err != nil {
		utils.SendError(c, http.StatusNotFound, err.Error())
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil detail properti", prop, nil)
}

func (h *PropertyHandler) GetOwnerProperties(c *gin.Context) {
	ownerID := c.GetUint("user_id")
	props, err := h.propService.GetOwnerProperties(ownerID)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal mengambil properti milik Anda")
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil daftar properti milik owner", props, nil)
}

func (h *PropertyHandler) CreateProperty(c *gin.Context) {
	ownerID := c.GetUint("user_id")

	var req dto.CreateOrUpdatePropertyRequest
	if err := c.ShouldBind(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Data form properti tidak lengkap/valid: "+err.Error())
		return
	}

	var files []*multipart.FileHeader
	if form, err := c.MultipartForm(); err == nil && form != nil {
		files = form.File["images"]
	}

	imagePaths, err := storage.SaveUploadedImages(c, files)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, err.Error())
		return
	}

	prop, err := h.propService.CreateProperty(ownerID, req, imagePaths)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal menambahkan properti: "+err.Error())
		return
	}

	utils.SendSuccess(c, http.StatusCreated, "Properti berhasil ditambahkan", prop, nil)
}

func (h *PropertyHandler) UpdateProperty(c *gin.Context) {
	ownerID := c.GetUint("user_id")
	propID, err := parseIDParam(c, "id")
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "ID properti tidak valid")
		return
	}

	var req dto.CreateOrUpdatePropertyRequest
	if err := c.ShouldBind(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Data pembaruan properti tidak valid: "+err.Error())
		return
	}

	var files []*multipart.FileHeader
	if form, err := c.MultipartForm(); err == nil && form != nil {
		files = form.File["images"]
	}

	var imagePaths []string
	if len(files) > 0 {
		imagePaths, err = storage.SaveUploadedImages(c, files)
		if err != nil {
			utils.SendError(c, http.StatusBadRequest, err.Error())
			return
		}
	}

	prop, err := h.propService.UpdateProperty(ownerID, propID, req, imagePaths)
	if err != nil {
		h.handleServiceError(c, err)
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Properti berhasil diperbarui", prop, nil)
}

func (h *PropertyHandler) UpdateAvailability(c *gin.Context) {
	ownerID := c.GetUint("user_id")
	propID, err := parseIDParam(c, "id")
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "ID properti tidak valid")
		return
	}

	var req dto.UpdateAvailabilityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Format ketersediaan kamar tidak valid: "+err.Error())
		return
	}

	prop, err := h.propService.UpdateAvailability(ownerID, propID, req)
	if err != nil {
		h.handleServiceError(c, err)
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Status ketersediaan properti berhasil diperbarui", prop, nil)
}

func (h *PropertyHandler) DeleteProperty(c *gin.Context) {
	ownerID := c.GetUint("user_id")
	propID, err := parseIDParam(c, "id")
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "ID properti tidak valid")
		return
	}

	if err := h.propService.DeleteProperty(ownerID, propID); err != nil {
		h.handleServiceError(c, err)
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Properti berhasil dihapus", nil, nil)
}

func (h *PropertyHandler) ToggleWishlist(c *gin.Context) {
	userID := c.GetUint("user_id")
	propID, err := parseIDParam(c, "property_id")
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "ID properti tidak valid")
		return
	}

	added, err := h.propService.ToggleWishlist(userID, propID)
	if err != nil {
		h.handleServiceError(c, err)
		return
	}

	msg := "Properti dihapus dari favorit (Wishlist)"
	if added {
		msg = "Properti ditambahkan ke favorit (Wishlist)"
	}

	utils.SendSuccess(c, http.StatusOK, msg, gin.H{"wishlisted": added}, nil)
}

func (h *PropertyHandler) GetWishlists(c *gin.Context) {
	userID := c.GetUint("user_id")
	items, err := h.propService.GetUserWishlists(userID)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Gagal mengambil daftar wishlist")
		return
	}

	utils.SendSuccess(c, http.StatusOK, "Berhasil mengambil daftar wishlist", items, nil)
}

func (h *PropertyHandler) handleServiceError(c *gin.Context, err error) {
	if errors.Is(err, services.ErrPropertyNotFound) {
		utils.SendError(c, http.StatusNotFound, err.Error())
		return
	}
	if errors.Is(err, services.ErrForbiddenAccess) {
		utils.SendError(c, http.StatusForbidden, err.Error())
		return
	}
	utils.SendError(c, http.StatusInternalServerError, err.Error())
}

func parseIDParam(c *gin.Context, paramName string) (uint, error) {
	val, err := strconv.ParseUint(c.Param(paramName), 10, 64)
	return uint(val), err
}
