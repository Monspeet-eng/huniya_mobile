package services

import (
	"encoding/json"
	"errors"
	"strings"

	"huniya-backend/internal/dto"
	"huniya-backend/internal/models"
	"huniya-backend/internal/repositories"
)

var (
	ErrPropertyNotFound = errors.New("properti tidak ditemukan")
	ErrForbiddenAccess  = errors.New("anda tidak memiliki hak akses atas properti ini")
)

type PropertyService interface {
	GetProperties(query dto.PropertyFilterQuery) ([]models.Property, int64, error)
	GetNearbyProperties(query dto.NearbyQuery) ([]models.Property, error)
	GetPropertyByID(id uint) (*models.Property, error)
	GetOwnerProperties(ownerID uint) ([]models.Property, error)
	CreateProperty(ownerID uint, req dto.CreateOrUpdatePropertyRequest, imagePaths []string) (*models.Property, error)
	UpdateProperty(ownerID, propertyID uint, req dto.CreateOrUpdatePropertyRequest, newImages []string) (*models.Property, error)
	UpdateAvailability(ownerID, propertyID uint, req dto.UpdateAvailabilityRequest) (*models.Property, error)
	DeleteProperty(ownerID, propertyID uint) error
	ToggleWishlist(userID, propertyID uint) (bool, error)
	GetUserWishlists(userID uint) ([]models.Wishlist, error)
}

type propertyService struct {
	propRepo repositories.PropertyRepository
}

func NewPropertyService(propRepo repositories.PropertyRepository) PropertyService {
	return &propertyService{propRepo: propRepo}
}

func (s *propertyService) GetProperties(query dto.PropertyFilterQuery) ([]models.Property, int64, error) {
	return s.propRepo.FindAllWithFilter(query)
}

func (s *propertyService) GetNearbyProperties(query dto.NearbyQuery) ([]models.Property, error) {
	if query.Radius <= 0 {
		query.Radius = 5.0
	}
	return s.propRepo.FindNearby(query.Lat, query.Lng, query.Radius, query.Type)
}

func (s *propertyService) GetPropertyByID(id uint) (*models.Property, error) {
	prop, err := s.propRepo.FindByID(id)
	if err != nil {
		return nil, ErrPropertyNotFound
	}
	return prop, nil
}

func (s *propertyService) GetOwnerProperties(ownerID uint) ([]models.Property, error) {
	return s.propRepo.FindByOwnerID(ownerID)
}

func (s *propertyService) CreateProperty(ownerID uint, req dto.CreateOrUpdatePropertyRequest, imagePaths []string) (*models.Property, error) {
	facilities := parseFacilities(req.FacilitiesRaw, req.Facilities)

	isAvailable := true
	if req.IsAvailable != nil {
		isAvailable = *req.IsAvailable
	} else if req.RoomAvailable == 0 {
		isAvailable = false
	}

	prop := &models.Property{
		OwnerID:       ownerID,
		Title:         strings.TrimSpace(req.Title),
		Type:          req.Type,
		Description:   strings.TrimSpace(req.Description),
		PriceMonthly:  req.PriceMonthly,
		RoomAvailable: req.RoomAvailable,
		IsAvailable:   isAvailable,
		Address:       strings.TrimSpace(req.Address),
		City:          strings.TrimSpace(req.City),
		Latitude:      req.Latitude,
		Longitude:     req.Longitude,
		Facilities:    facilities,
		Images:        imagePaths,
	}

	if err := s.propRepo.Create(prop); err != nil {
		return nil, err
	}

	return prop, nil
}

func (s *propertyService) UpdateProperty(ownerID, propertyID uint, req dto.CreateOrUpdatePropertyRequest, newImages []string) (*models.Property, error) {
	prop, err := s.propRepo.FindByID(propertyID)
	if err != nil {
		return nil, ErrPropertyNotFound
	}

	if prop.OwnerID != ownerID {
		return nil, ErrForbiddenAccess
	}

	prop.Title = strings.TrimSpace(req.Title)
	prop.Type = req.Type
	prop.Description = strings.TrimSpace(req.Description)
	prop.PriceMonthly = req.PriceMonthly
	prop.RoomAvailable = req.RoomAvailable
	prop.Address = strings.TrimSpace(req.Address)
	prop.City = strings.TrimSpace(req.City)
	prop.Latitude = req.Latitude
	prop.Longitude = req.Longitude

	if req.IsAvailable != nil {
		prop.IsAvailable = *req.IsAvailable
	} else {
		prop.IsAvailable = req.RoomAvailable > 0
	}

	facilities := parseFacilities(req.FacilitiesRaw, req.Facilities)
	if len(facilities) > 0 {
		prop.Facilities = facilities
	}

	if len(newImages) > 0 {
		prop.Images = newImages
	}

	if err := s.propRepo.Update(prop); err != nil {
		return nil, err
	}

	return prop, nil
}

func (s *propertyService) UpdateAvailability(ownerID, propertyID uint, req dto.UpdateAvailabilityRequest) (*models.Property, error) {
	prop, err := s.propRepo.FindByID(propertyID)
	if err != nil {
		return nil, ErrPropertyNotFound
	}

	if prop.OwnerID != ownerID {
		return nil, ErrForbiddenAccess
	}

	prop.IsAvailable = req.IsAvailable
	prop.RoomAvailable = req.RoomAvailable

	if err := s.propRepo.Update(prop); err != nil {
		return nil, err
	}

	return prop, nil
}

func (s *propertyService) DeleteProperty(ownerID, propertyID uint) error {
	prop, err := s.propRepo.FindByID(propertyID)
	if err != nil {
		return ErrPropertyNotFound
	}

	if prop.OwnerID != ownerID {
		return ErrForbiddenAccess
	}

	return s.propRepo.Delete(propertyID)
}

func (s *propertyService) ToggleWishlist(userID, propertyID uint) (bool, error) {
	if _, err := s.propRepo.FindByID(propertyID); err != nil {
		return false, ErrPropertyNotFound
	}
	return s.propRepo.ToggleWishlist(userID, propertyID)
}

func (s *propertyService) GetUserWishlists(userID uint) ([]models.Wishlist, error) {
	return s.propRepo.GetUserWishlists(userID)
}

func parseFacilities(raw string, fallback []string) []string {
	if len(fallback) > 0 {
		return fallback
	}
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return []string{}
	}
	var parsed []string
	if err := json.Unmarshal([]byte(raw), &parsed); err == nil {
		return parsed
	}
	// Fallback comma-separated
	parts := strings.Split(raw, ",")
	for _, p := range parts {
		trimmed := strings.TrimSpace(p)
		if trimmed != "" {
			parsed = append(parsed, trimmed)
		}
	}
	return parsed
}
