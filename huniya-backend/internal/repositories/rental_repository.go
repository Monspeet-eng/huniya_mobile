package repositories

import (
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
	"huniya-backend/internal/models"
)

type RentalRepository interface {
	Create(rental *models.Rental, tx *gorm.DB) error
	FindByID(id uint) (*models.Rental, error)
	FindByIDForUpdate(id uint, tx *gorm.DB) (*models.Rental, error)
	FindByTenantID(tenantID uint) ([]models.Rental, error)
	FindByOwnerID(ownerID uint) ([]models.Rental, error)
	Update(rental *models.Rental, tx *gorm.DB) error
	CreatePayment(payment *models.RentalPayment, tx *gorm.DB) error
	GetPayments(rentalID uint) ([]models.RentalPayment, error)
	FindDueRentals(dueInDays int) ([]models.Rental, error)
	GetDB() *gorm.DB
}

type rentalRepository struct {
	db *gorm.DB
}

func NewRentalRepository(db *gorm.DB) RentalRepository {
	return &rentalRepository{db: db}
}

func (r *rentalRepository) GetDB() *gorm.DB {
	return r.db
}

func (r *rentalRepository) Create(rental *models.Rental, tx *gorm.DB) error {
	db := r.db
	if tx != nil {
		db = tx
	}
	return db.Create(rental).Error
}

func (r *rentalRepository) FindByID(id uint) (*models.Rental, error) {
	var rental models.Rental
	err := r.db.Preload("Property").Preload("Tenant").First(&rental, id).Error
	if err != nil {
		return nil, err
	}
	return &rental, nil
}

func (r *rentalRepository) FindByIDForUpdate(id uint, tx *gorm.DB) (*models.Rental, error) {
	db := r.db
	if tx != nil {
		db = tx
	}
	var rental models.Rental
	err := db.Clauses(clause.Locking{Strength: "UPDATE"}).Preload("Property").Preload("Tenant").First(&rental, id).Error
	if err != nil {
		return nil, err
	}
	return &rental, nil
}

func (r *rentalRepository) FindByTenantID(tenantID uint) ([]models.Rental, error) {
	var rentals []models.Rental
	err := r.db.Preload("Property").Where("tenant_id = ?", tenantID).Order("created_at DESC").Find(&rentals).Error
	return rentals, err
}

func (r *rentalRepository) FindByOwnerID(ownerID uint) ([]models.Rental, error) {
	var rentals []models.Rental
	err := r.db.Preload("Property").Preload("Tenant").
		Joins("JOIN properties ON properties.id = rentals.property_id").
		Where("properties.owner_id = ?", ownerID).
		Order("rentals.created_at DESC").Find(&rentals).Error
	return rentals, err
}

func (r *rentalRepository) Update(rental *models.Rental, tx *gorm.DB) error {
	db := r.db
	if tx != nil {
		db = tx
	}
	return db.Save(rental).Error
}

func (r *rentalRepository) CreatePayment(payment *models.RentalPayment, tx *gorm.DB) error {
	db := r.db
	if tx != nil {
		db = tx
	}
	return db.Create(payment).Error
}

func (r *rentalRepository) GetPayments(rentalID uint) ([]models.RentalPayment, error) {
	var payments []models.RentalPayment
	err := r.db.Where("rental_id = ?", rentalID).Order("paid_at DESC").Find(&payments).Error
	return payments, err
}

func (r *rentalRepository) FindDueRentals(dueInDays int) ([]models.Rental, error) {
	var rentals []models.Rental
	threshold := time.Now().AddDate(0, 0, dueInDays)
	err := r.db.Preload("Property").Preload("Tenant").
		Where("status = ? AND next_due_date <= ?", models.RentalStatusActive, threshold).
		Find(&rentals).Error
	return rentals, err
}
