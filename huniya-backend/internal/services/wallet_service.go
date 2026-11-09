package services

import (
	"errors"
	"fmt"
	"huniya-backend/internal/models"
	"huniya-backend/internal/repositories"

	"gorm.io/gorm"
)

var (
	ErrWalletNotFound      = errors.New("wallet tidak ditemukan")
	ErrInsufficientBalance = errors.New("saldo tidak mencukupi")
)

type WalletService interface {
	GetWallet(userID uint) (*models.Wallet, error)
	TopUp(userID uint, amount float64) (*models.WalletTransaction, error)
	GetTransactions(userID uint) ([]models.WalletTransaction, error)
	PayWithWallet(userID uint, amount float64, txType, refID, desc string, tx *gorm.DB) (*models.WalletTransaction, error)
	CreditWallet(userID uint, amount float64, txType, refID, desc string, tx *gorm.DB) (*models.WalletTransaction, error)
}

type walletService struct {
	walletRepo repositories.WalletRepository
}

func NewWalletService(walletRepo repositories.WalletRepository) WalletService {
	return &walletService{walletRepo: walletRepo}
}

func (s *walletService) GetWallet(userID uint) (*models.Wallet, error) {
	wallet, err := s.walletRepo.GetByUserID(userID)
	if err == nil {
		return wallet, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	wallet = &models.Wallet{UserID: userID, Balance: 0}
	if err := s.walletRepo.Create(wallet); err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			return s.walletRepo.GetByUserID(userID)
		}
		return nil, err
	}
	return wallet, nil
}

func (s *walletService) TopUp(userID uint, amount float64) (*models.WalletTransaction, error) {
	if amount <= 0 {
		return nil, errors.New("nominal top-up harus lebih dari 0")
	}

	wallet, err := s.GetWallet(userID)
	if err != nil {
		return nil, err
	}

	tx := s.walletRepo.GetDB().Begin()
	if tx.Error != nil {
		return nil, tx.Error
	}
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := s.walletRepo.UpdateBalance(wallet.ID, amount, tx); err != nil {
		tx.Rollback()
		return nil, err
	}

	// Reload balance after update
	var updatedWallet models.Wallet
	if err := tx.First(&updatedWallet, wallet.ID).Error; err != nil {
		tx.Rollback()
		return nil, err
	}

	walletTx := &models.WalletTransaction{
		WalletID:     wallet.ID,
		UserID:       userID,
		Type:         models.WalletTxTypeTopup,
		Amount:       amount,
		BalanceAfter: updatedWallet.Balance,
		Description:  fmt.Sprintf("Top up saldo sebesar Rp%.2f", amount),
		Status:       models.WalletTxStatusSuccess,
	}

	if err := s.walletRepo.CreateTransaction(walletTx, tx); err != nil {
		tx.Rollback()
		return nil, err
	}

	return walletTx, tx.Commit().Error
}

func (s *walletService) GetTransactions(userID uint) ([]models.WalletTransaction, error) {
	wallet, err := s.GetWallet(userID)
	if err != nil {
		return nil, err
	}
	return s.walletRepo.GetTransactions(wallet.ID)
}

func (s *walletService) PayWithWallet(userID uint, amount float64, txType, refID, desc string, tx *gorm.DB) (*models.WalletTransaction, error) {
	if amount <= 0 {
		return nil, errors.New("nominal pembayaran harus lebih dari 0")
	}

	wallet, err := s.GetWallet(userID)
	if err != nil {
		return nil, err
	}

	useLocalTx := false
	if tx == nil {
		tx = s.walletRepo.GetDB().Begin()
		useLocalTx = true
		if tx.Error != nil {
			return nil, tx.Error
		}
	}

	balanceAfter, err := s.walletRepo.DebitBalance(wallet.ID, amount, tx)
	if err != nil {
		if useLocalTx {
			tx.Rollback()
		}
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrInsufficientBalance
		}
		return nil, err
	}

	walletTx := &models.WalletTransaction{
		WalletID:     wallet.ID,
		UserID:       userID,
		Type:         txType,
		Amount:       -amount,
		BalanceAfter: balanceAfter,
		ReferenceID:  refID,
		Description:  desc,
		Status:       models.WalletTxStatusSuccess,
	}

	if err := s.walletRepo.CreateTransaction(walletTx, tx); err != nil {
		if useLocalTx {
			tx.Rollback()
		}
		return nil, err
	}

	if useLocalTx {
		if err := tx.Commit().Error; err != nil {
			return nil, err
		}
	}

	return walletTx, nil
}

func (s *walletService) CreditWallet(userID uint, amount float64, txType, refID, desc string, tx *gorm.DB) (*models.WalletTransaction, error) {
	if amount <= 0 {
		return nil, errors.New("nominal kredit harus lebih dari 0")
	}

	wallet, err := s.GetWallet(userID)
	if err != nil {
		return nil, err
	}

	useLocalTx := false
	if tx == nil {
		tx = s.walletRepo.GetDB().Begin()
		useLocalTx = true
		if tx.Error != nil {
			return nil, tx.Error
		}
	}

	if err := s.walletRepo.UpdateBalance(wallet.ID, amount, tx); err != nil {
		if useLocalTx {
			tx.Rollback()
		}
		return nil, err
	}
	var updatedWallet models.Wallet
	if err := tx.First(&updatedWallet, wallet.ID).Error; err != nil {
		if useLocalTx {
			tx.Rollback()
		}
		return nil, err
	}

	walletTx := &models.WalletTransaction{
		WalletID:     wallet.ID,
		UserID:       userID,
		Type:         txType,
		Amount:       amount,
		BalanceAfter: updatedWallet.Balance,
		ReferenceID:  refID,
		Description:  desc,
		Status:       models.WalletTxStatusSuccess,
	}

	if err := s.walletRepo.CreateTransaction(walletTx, tx); err != nil {
		if useLocalTx {
			tx.Rollback()
		}
		return nil, err
	}

	if useLocalTx {
		if err := tx.Commit().Error; err != nil {
			return nil, err
		}
	}

	return walletTx, nil
}
