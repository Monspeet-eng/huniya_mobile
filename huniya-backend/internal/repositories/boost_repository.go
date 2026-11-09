package repositories

import (
	"time"

	"huniya-backend/internal/models"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type BoostRepository interface {
	Create(boost *models.BoostAd, tx *gorm.DB) error
	FindActiveByPropertyID(propertyID uint) (*models.BoostAd, error)
	GetActiveBoosts() ([]models.BoostAd, error)
	FindActiveByPropertyIDForUpdate(propertyID uint, tx *gorm.DB) (*models.BoostAd, error)
	GetDB() *gorm.DB
}

type boostRepository struct {
	db *gorm.DB
}

func NewBoostRepository(db *gorm.DB) BoostRepository {
	return &boostRepository{db: db}
}

func (r *boostRepository) GetDB() *gorm.DB {
	return r.db
}

func (r *boostRepository) Create(boost *models.BoostAd, tx *gorm.DB) error {
	db := r.db
	if tx != nil {
		db = tx
	}
	return db.Create(boost).Error
}

func (r *boostRepository) FindActiveByPropertyID(propertyID uint) (*models.BoostAd, error) {
	var boost models.BoostAd
	now := time.Now()
	err := r.db.Where("property_id = ? AND status = ? AND starts_at <= ? AND expires_at >= ?",
		propertyID, models.BoostStatusActive, now, now).First(&boost).Error
	if err != nil {
		return nil, err
	}
	return &boost, nil
}

func (r *boostRepository) FindActiveByPropertyIDForUpdate(propertyID uint, tx *gorm.DB) (*models.BoostAd, error) {
	db := r.db
	if tx != nil {
		db = tx
	}
	var boost models.BoostAd
	now := time.Now()
	err := db.Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("property_id = ? AND status = ? AND starts_at <= ? AND expires_at >= ?",
			propertyID, models.BoostStatusActive, now, now).
		First(&boost).Error
	if err != nil {
		return nil, err
	}
	return &boost, nil
}

func (r *boostRepository) GetActiveBoosts() ([]models.BoostAd, error) {
	var boosts []models.BoostAd
	now := time.Now()
	err := r.db.Preload("Property").
		Where("status = ? AND starts_at <= ? AND expires_at >= ?",
			models.BoostStatusActive, now, now).Find(&boosts).Error
	return boosts, err
}
