package models

import "time"

const (
	RentalStatusActive   = "active"
	RentalStatusPending  = "pending"
	RentalStatusExpired  = "expired"
	RentalStatusCanceled = "canceled"
)

type Rental struct {
	ID           uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	TenantID     uint      `gorm:"not null;index" json:"tenant_id"`
	Tenant       User      `gorm:"foreignKey:TenantID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"tenant,omitempty"`
	PropertyID   uint      `gorm:"not null;index" json:"property_id"`
	Property     Property  `gorm:"foreignKey:PropertyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"property,omitempty"`
	StartDate    time.Time `gorm:"not null" json:"start_date"`
	EndDate      time.Time `gorm:"not null" json:"end_date"`
	NextDueDate  time.Time `gorm:"not null;index" json:"next_due_date"`
	MonthlyPrice float64   `gorm:"type:numeric(12,2);not null" json:"monthly_price"`
	Status       string    `gorm:"type:varchar(20);default:'active';not null;index" json:"status"`
	CreatedAt    time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt    time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

type RentalPayment struct {
	ID            uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	RentalID      uint      `gorm:"not null;index" json:"rental_id"`
	TenantID      uint      `gorm:"not null;index" json:"tenant_id"`
	OwnerID       uint      `gorm:"not null;index" json:"owner_id"`
	MonthsCount   int       `gorm:"not null;default:1" json:"months_count"`
	TotalAmount   float64   `gorm:"type:numeric(15,2);not null" json:"total_amount"`
	PaymentMethod string    `gorm:"type:varchar(30);default:'wallet';not null" json:"payment_method"`
	TransactionID uint      `gorm:"index" json:"transaction_id"`
	PaidAt        time.Time `gorm:"autoCreateTime" json:"paid_at"`
}
