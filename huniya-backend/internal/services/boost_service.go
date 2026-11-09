package services

import (
	"errors"
	"fmt"
	"huniya-backend/internal/models"
	"huniya-backend/internal/repositories"
	"time"

	"gorm.io/gorm"
)

var (
	ErrBoostNotFound = errors.New("boost iklan tidak ditemukan")
)

const (
	BoostPricePerMonth = 50000.0 // Rp 50.000/bulan untuk boost
)

type BoostService interface {
	PurchaseBoost(ownerID, propertyID uint, monthsCount int) (*models.BoostAd, error)
	GetPropertyBoost(ownerID, propertyID uint) (*models.BoostAd, error)
	GetBoostedProperties() ([]models.Property, error)
}

type boostService struct {
	boostRepo repositories.BoostRepository
	propRepo  repositories.PropertyRepository
	walletSvc WalletService
}

func NewBoostService(boostRepo repositories.BoostRepository, propRepo repositories.PropertyRepository, walletSvc WalletService) BoostService {
	return &boostService{
		boostRepo: boostRepo,
		propRepo:  propRepo,
		walletSvc: walletSvc,
	}
}

func (s *boostService) PurchaseBoost(ownerID, propertyID uint, monthsCount int) (*models.BoostAd, error) {
	if monthsCount < 1 {
		monthsCount = 1
	}
	if monthsCount > 12 {
		monthsCount = 12
	}

	tx := s.boostRepo.GetDB().Begin()
	if tx.Error != nil {
		return nil, tx.Error
	}
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Lock property row so concurrent boost purchases serialize even when no boost row exists yet.
	prop, err := s.propRepo.FindByIDForUpdate(propertyID, tx)
	if err != nil {
		tx.Rollback()
		return nil, ErrPropertyNotFound
	}
	if prop.OwnerID != ownerID {
		tx.Rollback()
		return nil, ErrForbiddenAccess
	}

	// Prop row lock serializes this check and subsequent boost creation.
	existing, err := s.boostRepo.FindActiveByPropertyIDForUpdate(propertyID, tx)
	if err == nil && existing != nil {
		tx.Rollback()
		return nil, errors.New("properti ini sudah memiliki boost aktif, tunggu hingga expired atau batalkan boost lama")
	}
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		tx.Rollback()
		return nil, err
	}

	totalAmount := BoostPricePerMonth * float64(monthsCount)


	// 1. Deduct owner wallet
	desc := fmt.Sprintf("Pembelian boost iklan %s (%d bulan)", prop.Title, monthsCount)
	refID := fmt.Sprintf("BOOST-%d-%d", ownerID, time.Now().Unix())
	_, err = s.walletSvc.PayWithWallet(ownerID, totalAmount, models.WalletTxTypeBoostAd, refID, desc, tx)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	// 2. Create boost record
	now := time.Now()
	boost := &models.BoostAd{
		PropertyID:  propertyID,
		OwnerID:     ownerID,
		MonthsCount: monthsCount,
		Amount:      totalAmount,
		StartsAt:    now,
		ExpiresAt:   now.AddDate(0, monthsCount, 0),
		Status:      models.BoostStatusActive,
		PaymentRef:  refID,
	}

	if err := s.boostRepo.Create(boost, tx); err != nil {
		tx.Rollback()
		return nil, err
	}

	return boost, tx.Commit().Error
}

func (s *boostService) GetPropertyBoost(ownerID, propertyID uint) (*models.BoostAd, error) {
	prop, err := s.propRepo.FindByID(propertyID)
	if err != nil {
		return nil, ErrPropertyNotFound
	}
	if prop.OwnerID != ownerID {
		return nil, ErrForbiddenAccess
	}
	return s.boostRepo.FindActiveByPropertyID(propertyID)
}

func (s *boostService) GetBoostedProperties() ([]models.Property, error) {
	boosts, err := s.boostRepo.GetActiveBoosts()
	if err != nil {
		return nil, err
	}
	properties := make([]models.Property, len(boosts))
	for i, b := range boosts {
		properties[i] = b.Property
	}
	return properties, nil
}
