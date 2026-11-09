package models

import "time"

type Wishlist struct {
	ID         uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID     uint      `gorm:"not null;index" json:"user_id"`
	PropertyID uint      `gorm:"not null;index" json:"property_id"`
	Property   Property  `gorm:"foreignKey:PropertyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"property"`
	CreatedAt  time.Time `gorm:"autoCreateTime" json:"created_at"`
}
