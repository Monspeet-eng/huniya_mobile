package services

import (
	"errors"
	"fmt"
	"huniya-backend/internal/models"
	"huniya-backend/internal/repositories"
	"time"
)

var (
	ErrRentalNotFound = errors.New("sewa tidak ditemukan")
)

type RentalService interface {
	CreateRental(tenantID, propertyID uint, monthsCount int) (*models.Rental, error)
	PayRent(tenantID, rentalID uint, monthsCount int) (*models.RentalPayment, error)
	GetUserRentals(tenantID uint) ([]models.Rental, error)
	GetOwnerRentals(ownerID uint) ([]models.Rental, error)
	GetDueReminders(tenantID uint) ([]models.Rental, error)
}

type rentalService struct {
	rentalRepo repositories.RentalRepository
	propRepo   repositories.PropertyRepository
	walletSvc  WalletService
}

func NewRentalService(rentalRepo repositories.RentalRepository, propRepo repositories.PropertyRepository, walletSvc WalletService) RentalService {
	return &rentalService{
		rentalRepo: rentalRepo,
		propRepo:   propRepo,
		walletSvc:  walletSvc,
	}
}

func (s *rentalService) CreateRental(tenantID, propertyID uint, monthsCount int) (*models.Rental, error) {
	if monthsCount < 1 {
		monthsCount = 1
	}

	prop, err := s.propRepo.FindByID(propertyID)
	if err != nil {
		return nil, ErrPropertyNotFound
	}
	if !prop.IsAvailable || prop.RoomAvailable <= 0 {
		return nil, errors.New("kamar tidak tersedia untuk disewa")
	}

	now := time.Now()
	endDate := now.AddDate(0, monthsCount, 0)
	totalPrice := prop.PriceMonthly * float64(monthsCount)

	tx := s.rentalRepo.GetDB().Begin()
	if tx.Error != nil {
		return nil, tx.Error
	}
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 1. Pay with wallet
	desc := fmt.Sprintf("Pembayaran awal sewa %s (%d bulan)", prop.Title, monthsCount)
	wTx, err := s.walletSvc.PayWithWallet(tenantID, totalPrice, models.WalletTxTypeRentPayment, fmt.Sprintf("PROP-%d", propertyID), desc, tx)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	// 2. Create rental record
	rental := &models.Rental{
		TenantID:     tenantID,
		PropertyID:   propertyID,
		StartDate:    now,
		EndDate:      endDate,
		NextDueDate:  endDate,
		MonthlyPrice: prop.PriceMonthly,
		Status:       models.RentalStatusActive,
	}
	if err := s.rentalRepo.Create(rental, tx); err != nil {
		tx.Rollback()
		return nil, err
	}

	// Reserve one room atomically inside same transaction.
	if err := s.propRepo.ReserveRoom(propertyID, tx); err != nil {
		tx.Rollback()
		return nil, err
	}

	// 3. Create payment record
	payment := &models.RentalPayment{
		RentalID:      rental.ID,
		TenantID:      tenantID,
		OwnerID:       prop.OwnerID,
		MonthsCount:   monthsCount,
		TotalAmount:   totalPrice,
		PaymentMethod: "wallet",
		TransactionID: wTx.ID,
	}
	if err := s.rentalRepo.CreatePayment(payment, tx); err != nil {
		tx.Rollback()
		return nil, err
	}

	// 4. Credit owner wallet
	ownerWalletDesc := fmt.Sprintf("Penerimaan sewa %s (%d bulan)", prop.Title, monthsCount)
	if _, err := s.walletSvc.CreditWallet(prop.OwnerID, totalPrice, models.WalletTxTypeRentPayout, fmt.Sprintf("RENT-%d", rental.ID), ownerWalletDesc, tx); err != nil {
		tx.Rollback()
		return nil, err
	}

	return rental, tx.Commit().Error
}

func (s *rentalService) PayRent(tenantID, rentalID uint, monthsCount int) (*models.RentalPayment, error) {
	if monthsCount < 1 {
		monthsCount = 1
	}

	tx := s.rentalRepo.GetDB().Begin()
	if tx.Error != nil {
		return nil, tx.Error
	}
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Acquire row lock to prevent race condition during simultaneous extensions
	rental, err := s.rentalRepo.FindByIDForUpdate(rentalID, tx)
	if err != nil {
		tx.Rollback()
		return nil, ErrRentalNotFound
	}
	if rental.TenantID != tenantID {
		tx.Rollback()
		return nil, ErrForbiddenAccess
	}
	if rental.Status != models.RentalStatusActive {
		tx.Rollback()
		return nil, errors.New("hanya sewa aktif yang dapat dibayar/diperpanjang")
	}

	totalPrice := rental.MonthlyPrice * float64(monthsCount)

	// 1. Deduct tenant wallet
	desc := fmt.Sprintf("Perpanjangan sewa %s (%d bulan)", rental.Property.Title, monthsCount)
	wTx, err := s.walletSvc.PayWithWallet(tenantID, totalPrice, models.WalletTxTypeRentPayment, fmt.Sprintf("RENT-%d", rental.ID), desc, tx)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	// 2. Extend rental dates
	newEndDate := rental.EndDate.AddDate(0, monthsCount, 0)
	rental.EndDate = newEndDate
	rental.NextDueDate = newEndDate
	rental.Status = models.RentalStatusActive
	if err := s.rentalRepo.Update(rental, tx); err != nil {
		tx.Rollback()
		return nil, err
	}

	// 3. Record payment
	payment := &models.RentalPayment{
		RentalID:      rental.ID,
		TenantID:      tenantID,
		OwnerID:       rental.Property.OwnerID,
		MonthsCount:   monthsCount,
		TotalAmount:   totalPrice,
		PaymentMethod: "wallet",
		TransactionID: wTx.ID,
	}
	if err := s.rentalRepo.CreatePayment(payment, tx); err != nil {
		tx.Rollback()
		return nil, err
	}

	// 4. Payout owner wallet
	ownerDesc := fmt.Sprintf("Penerimaan perpanjangan sewa %s (%d bulan)", rental.Property.Title, monthsCount)
	if _, err := s.walletSvc.CreditWallet(rental.Property.OwnerID, totalPrice, models.WalletTxTypeRentPayout, fmt.Sprintf("RENT-%d", rental.ID), ownerDesc, tx); err != nil {
		tx.Rollback()
		return nil, err
	}

	return payment, tx.Commit().Error
}

func (s *rentalService) GetUserRentals(tenantID uint) ([]models.Rental, error) {
	return s.rentalRepo.FindByTenantID(tenantID)
}

func (s *rentalService) GetOwnerRentals(ownerID uint) ([]models.Rental, error) {
	return s.rentalRepo.FindByOwnerID(ownerID)
}

func (s *rentalService) GetDueReminders(tenantID uint) ([]models.Rental, error) {
	rentals, err := s.rentalRepo.FindByTenantID(tenantID)
	if err != nil {
		return nil, err
	}

	var dueList []models.Rental
	now := time.Now()
	threshold := now.AddDate(0, 0, 7) // Remind if due within 7 days or overdue

	for _, r := range rentals {
		if r.Status == models.RentalStatusActive && (r.NextDueDate.Before(threshold) || r.NextDueDate.Before(now)) {
			dueList = append(dueList, r)
		}
	}
	return dueList, nil
}
