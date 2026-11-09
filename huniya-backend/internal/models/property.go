package models

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"
)

const (
	TypeKostPutra  = "kost_putra"
	TypeKostPutri  = "kost_putri"
	TypeKostCampur = "kost_campur"
	TypeKontrakan  = "kontrakan"
)

// StringSlice merepresentasikan kolom JSONB array string di PostgreSQL
type StringSlice []string

func (s StringSlice) Value() (driver.Value, error) {
	if s == nil {
		return "[]", nil
	}
	b, err := json.Marshal(s)
	return string(b), err
}

func (s *StringSlice) Scan(value interface{}) error {
	if value == nil {
		*s = []string{}
		return nil
	}
	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return errors.New("gagal melakukan scan tipe JSONB ke StringSlice")
	}
	return json.Unmarshal(bytes, s)
}

type Property struct {
	ID            uint        `gorm:"primaryKey;autoIncrement" json:"id"`
	OwnerID       uint        `gorm:"not null;index" json:"owner_id"`
	Owner         User        `gorm:"foreignKey:OwnerID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"owner,omitempty"`
	Title         string      `gorm:"type:varchar(150);not null" json:"title"`
	Type          string      `gorm:"type:varchar(30);not null;index" json:"type"`
	Description   string      `gorm:"type:text;not null" json:"description"`
	PriceMonthly  float64     `gorm:"type:numeric(12,2);not null" json:"price_monthly"`
	RoomAvailable int         `gorm:"default:1;not null" json:"room_available"`
	IsAvailable   bool        `gorm:"default:true;not null" json:"is_available"`
	Address       string      `gorm:"type:text;not null" json:"address"`
	City          string      `gorm:"type:varchar(100);not null;index" json:"city"`
	Latitude      float64     `gorm:"type:double precision;not null" json:"latitude"`
	Longitude     float64     `gorm:"type:double precision;not null" json:"longitude"`
	Facilities    StringSlice `gorm:"type:jsonb;default:'[]'" json:"facilities"`
	Images        StringSlice `gorm:"type:jsonb;default:'[]'" json:"images"`
	DistanceKM    *float64    `gorm:"->;column:distance_km" json:"distance_km,omitempty"`
	CreatedAt     time.Time   `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt     time.Time   `gorm:"autoUpdateTime" json:"updated_at"`
}
