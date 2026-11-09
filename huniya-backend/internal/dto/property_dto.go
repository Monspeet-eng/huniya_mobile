package dto

import "huniya-backend/internal/models"

type PropertyFilterQuery struct {
	Search   string  `form:"search"`
	Type     string  `form:"type"`
	MinPrice float64 `form:"min_price"`
	MaxPrice float64 `form:"max_price"`
	City     string  `form:"city"`
	Page     int     `form:"page,default=1"`
	Limit    int     `form:"limit,default=10"`
}

type NearbyQuery struct {
	Lat    float64 `form:"lat" binding:"required"`
	Lng    float64 `form:"lng" binding:"required"`
	Radius float64 `form:"radius,default=5"`
	Type   string  `form:"type"`
}

type CreateOrUpdatePropertyRequest struct {
	Title         string   `form:"title" json:"title" binding:"required,max=150"`
	Type          string   `form:"type" json:"type" binding:"required,oneof=kost_putra kost_putri kost_campur kontrakan"`
	Description   string   `form:"description" json:"description" binding:"required"`
	PriceMonthly  float64  `form:"price_monthly" json:"price_monthly" binding:"required,gt=0"`
	RoomAvailable int      `form:"room_available" json:"room_available" binding:"min=0"`
	IsAvailable   *bool    `form:"is_available" json:"is_available"`
	Address       string   `form:"address" json:"address" binding:"required"`
	City          string   `form:"city" json:"city" binding:"required"`
	Latitude      float64  `form:"latitude" json:"latitude" binding:"required"`
	Longitude     float64  `form:"longitude" json:"longitude" binding:"required"`
	FacilitiesRaw string   `form:"facilities" json:"-"`
	Facilities    []string `json:"facilities"`
}

type UpdateAvailabilityRequest struct {
	IsAvailable   bool `json:"is_available"`
	RoomAvailable int  `json:"room_available" binding:"min=0"`
}

type PropertyDetailResponse struct {
	models.Property
	OwnerInfo models.OwnerBasicInfo `json:"owner"`
}
