package models

import "time"

const (
	WalletTxTypeTopup       = "topup"
	WalletTxTypeRentPayment = "rent_payment"
	WalletTxTypeRentPayout  = "rent_payout"
	WalletTxTypeBoostAd     = "boost_ad"

	WalletTxStatusSuccess = "success"
	WalletTxStatusPending = "pending"
	WalletTxStatusFailed  = "failed"
)

type Wallet struct {
	ID        uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID    uint      `gorm:"uniqueIndex;not null" json:"user_id"`
	User      User      `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"user,omitempty"`
	Balance   float64   `gorm:"type:numeric(15,2);default:0;not null" json:"balance"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

type WalletTransaction struct {
	ID           uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	WalletID     uint      `gorm:"not null;index" json:"wallet_id"`
	UserID       uint      `gorm:"not null;index" json:"user_id"`
	Type         string    `gorm:"type:varchar(30);not null;index" json:"type"`
	Amount       float64   `gorm:"type:numeric(15,2);not null" json:"amount"`
	BalanceAfter float64   `gorm:"type:numeric(15,2);not null" json:"balance_after"`
	ReferenceID  string    `gorm:"type:varchar(100);index" json:"reference_id,omitempty"`
	Description  string    `gorm:"type:text" json:"description"`
	Status       string    `gorm:"type:varchar(20);default:'success';not null" json:"status"`
	CreatedAt    time.Time `gorm:"autoCreateTime" json:"created_at"`
}
