package models

import "time"

const (
	BoostStatusActive  = "active"
	BoostStatusPending = "pending"
	BoostStatusExpired = "expired"
	BoostStatusFailed  = "failed"
)

type BoostAd struct {
	ID          uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	PropertyID  uint      `gorm:"not null;index" json:"property_id"`
	Property    Property  `gorm:"foreignKey:PropertyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"property,omitempty"`
	OwnerID     uint      `gorm:"not null;index" json:"owner_id"`
	MonthsCount int       `gorm:"not null;default:1" json:"months_count"`
	Amount      float64   `gorm:"type:numeric(12,2);not null" json:"amount"`
	StartsAt    time.Time `gorm:"not null;index" json:"starts_at"`
	ExpiresAt   time.Time `gorm:"not null;index" json:"expires_at"`
	Status      string    `gorm:"type:varchar(20);default:'active';not null;index" json:"status"`
	PaymentRef  string    `gorm:"type:varchar(100);uniqueIndex;not null" json:"payment_ref"`
	CreatedAt   time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}
