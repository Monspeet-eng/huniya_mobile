package repositories

import (
	"strings"

	"huniya-backend/internal/dto"
	"huniya-backend/internal/models"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type PropertyRepository interface {
	Create(property *models.Property) error
	Update(property *models.Property) error
	Delete(id uint) error
	FindByID(id uint) (*models.Property, error)
	FindByIDForUpdate(id uint, tx *gorm.DB) (*models.Property, error)
	FindAllWithFilter(query dto.PropertyFilterQuery) ([]models.Property, int64, error)
	FindNearby(lat, lng, radiusKM float64, propType string) ([]models.Property, error)
	FindByOwnerID(ownerID uint) ([]models.Property, error)
	ToggleWishlist(userID, propertyID uint) (bool, error)
	GetUserWishlists(userID uint) ([]models.Wishlist, error)
	ReserveRoom(propertyID uint, tx *gorm.DB) error
}

type propertyRepository struct {
	db *gorm.DB
}

func NewPropertyRepository(db *gorm.DB) PropertyRepository {
	return &propertyRepository{db: db}
}

func (r *propertyRepository) Create(property *models.Property) error {
	return r.db.Create(property).Error
}

func (r *propertyRepository) Update(property *models.Property) error {
	return r.db.Save(property).Error
}

func (r *propertyRepository) Delete(id uint) error {
	return r.db.Delete(&models.Property{}, id).Error
}

func (r *propertyRepository) FindByID(id uint) (*models.Property, error) {
	var property models.Property
	if err := r.db.Preload("Owner").First(&property, id).Error; err != nil {
		return nil, err
	}
	return &property, nil
}

func (r *propertyRepository) FindByIDForUpdate(id uint, tx *gorm.DB) (*models.Property, error) {
	db := r.db
	if tx != nil {
		db = tx
	}
	var property models.Property
	if err := db.Clauses(clause.Locking{Strength: "UPDATE"}).Preload("Owner").First(&property, id).Error; err != nil {
		return nil, err
	}
	return &property, nil
}

// ReserveRoom atomically decrements available inventory and closes the listing
// when its final room is reserved.
func (r *propertyRepository) ReserveRoom(propertyID uint, tx *gorm.DB) error {
	db := r.db
	if tx != nil {
		db = tx
	}

	result := db.Model(&models.Property{}).
		Where("id = ? AND is_available = ? AND room_available > 0", propertyID, true).
		Updates(map[string]interface{}{
			"room_available": gorm.Expr("room_available - ?", 1),
			"is_available":  gorm.Expr("room_available - ? > 0", 1),
		})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *propertyRepository) FindAllWithFilter(q dto.PropertyFilterQuery) ([]models.Property, int64, error) {
	var properties []models.Property
	var total int64

	tx := r.db.Model(&models.Property{}).Preload("Owner")

	if q.Search != "" {
		likeQuery := "%" + strings.ToLower(q.Search) + "%"
		tx = tx.Where("LOWER(title) LIKE ? OR LOWER(address) LIKE ? OR LOWER(city) LIKE ?", likeQuery, likeQuery, likeQuery)
	}

	if q.Type != "" && q.Type != "all" {
		tx = tx.Where("type = ?", q.Type)
	}

	if q.City != "" {
		tx = tx.Where("LOWER(city) = ?", strings.ToLower(q.City))
	}

	if q.MinPrice > 0 {
		tx = tx.Where("price_monthly >= ?", q.MinPrice)
	}

	if q.MaxPrice > 0 {
		tx = tx.Where("price_monthly <= ?", q.MaxPrice)
	}

	if err := tx.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if q.Page < 1 {
		q.Page = 1
	}
	if q.Limit < 1 || q.Limit > 100 {
		q.Limit = 10
	}
	offset := (q.Page - 1) * q.Limit

	err := tx.Order("created_at DESC").Limit(q.Limit).Offset(offset).Find(&properties).Error
	return properties, total, err
}

// FindNearby mengeksekusi query Haversine Formula di PostgreSQL sesuai Bagian 5 PRD
func (r *propertyRepository) FindNearby(lat, lng, radiusKM float64, propType string) ([]models.Property, error) {
	var properties []models.Property

	haversineExpr := `(
		6371 * acos(
			LEAST(1.0, GREATEST(-1.0,
				cos(radians(@user_lat)) * cos(radians(p.latitude)) *
				cos(radians(p.longitude) - radians(@user_lng)) +
				sin(radians(@user_lat)) * sin(radians(p.latitude))
			))
		)
	)`

	baseSQL := `
		SELECT 
			p.*,
			` + haversineExpr + ` AS distance_km
		FROM properties p
		WHERE p.is_available = true
		  AND ` + haversineExpr + ` <= @radius_km
	`

	params := map[string]interface{}{
		"user_lat":  lat,
		"user_lng":  lng,
		"radius_km": radiusKM,
	}

	if propType != "" && propType != "all" {
		baseSQL += ` AND p.type = @prop_type`
		params["prop_type"] = propType
	}

	baseSQL += ` ORDER BY distance_km ASC;`

	if err := r.db.Raw(baseSQL, params).Scan(&properties).Error; err != nil {
		return nil, err
	}

	return properties, nil
}

func (r *propertyRepository) FindByOwnerID(ownerID uint) ([]models.Property, error) {
	var properties []models.Property
	err := r.db.Where("owner_id = ?", ownerID).Order("created_at DESC").Find(&properties).Error
	return properties, err
}

func (r *propertyRepository) ToggleWishlist(userID, propertyID uint) (bool, error) {
	var existing models.Wishlist
	err := r.db.Where("user_id = ? AND property_id = ?", userID, propertyID).First(&existing).Error

	if err == nil {
		// Sudah ada di wishlist -> hapus (un-wishlist)
		if delErr := r.db.Delete(&existing).Error; delErr != nil {
			return false, delErr
		}
		return false, nil
	}

	// Belum ada -> tambahkan ke wishlist
	newWish := models.Wishlist{
		UserID:     userID,
		PropertyID: propertyID,
	}
	if createErr := r.db.Create(&newWish).Error; createErr != nil {
		return false, createErr
	}
	return true, nil
}

func (r *propertyRepository) GetUserWishlists(userID uint) ([]models.Wishlist, error) {
	var wishlists []models.Wishlist
	err := r.db.Preload("Property").Preload("Property.Owner").
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Find(&wishlists).Error
	return wishlists, err
}
