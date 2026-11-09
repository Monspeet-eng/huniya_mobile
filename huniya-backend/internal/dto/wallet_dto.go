package dto

type TopUpRequest struct {
	Amount float64 `json:"amount" binding:"required,gt=0"`
}

type CreateRentalRequest struct {
	PropertyID  uint `json:"property_id" binding:"required"`
	MonthsCount int  `json:"months_count" binding:"required,min=1,max=24"`
}

type PayRentRequest struct {
	MonthsCount int `json:"months_count" binding:"required,min=1,max=24"`
}

type PurchaseBoostRequest struct {
	MonthsCount int `json:"months_count" binding:"required,min=1,max=12"`
}
