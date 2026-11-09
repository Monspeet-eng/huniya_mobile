package repositories

import (
	"gorm.io/gorm"
	"huniya-backend/internal/models"
)

type WalletRepository interface {
	GetByUserID(userID uint) (*models.Wallet, error)
	Create(wallet *models.Wallet) error
	UpdateBalance(walletID uint, amount float64, tx *gorm.DB) error
	DebitBalance(walletID uint, amount float64, tx *gorm.DB) (float64, error)
	CreateTransaction(transaction *models.WalletTransaction, tx *gorm.DB) error
	GetTransactions(walletID uint) ([]models.WalletTransaction, error)
	GetDB() *gorm.DB
}

type walletRepository struct {
	db *gorm.DB
}

func NewWalletRepository(db *gorm.DB) WalletRepository {
	return &walletRepository{db: db}
}

func (r *walletRepository) GetByUserID(userID uint) (*models.Wallet, error) {
	var wallet models.Wallet
	err := r.db.Where("user_id = ?", userID).First(&wallet).Error
	if err != nil {
		return nil, err
	}
	return &wallet, nil
}

func (r *walletRepository) Create(wallet *models.Wallet) error {
	return r.db.Create(wallet).Error
}

func (r *walletRepository) GetDB() *gorm.DB {
	return r.db
}

func (r *walletRepository) UpdateBalance(walletID uint, amount float64, tx *gorm.DB) error {
	db := r.db
	if tx != nil {
		db = tx
	}
	return db.Model(&models.Wallet{}).Where("id = ?", walletID).
		Update("balance", gorm.Expr("balance + ?", amount)).Error
}

func (r *walletRepository) DebitBalance(walletID uint, amount float64, tx *gorm.DB) (float64, error) {
	db := r.db
	if tx != nil {
		db = tx
	}
	result := db.Model(&models.Wallet{}).
		Where("id = ? AND balance >= ?", walletID, amount).
		Update("balance", gorm.Expr("balance - ?", amount))
	if result.Error != nil {
		return 0, result.Error
	}
	if result.RowsAffected == 0 {
		return 0, gorm.ErrRecordNotFound
	}
	var wallet models.Wallet
	if err := db.First(&wallet, walletID).Error; err != nil {
		return 0, err
	}
	return wallet.Balance, nil
}

func (r *walletRepository) CreateTransaction(transaction *models.WalletTransaction, tx *gorm.DB) error {
	db := r.db
	if tx != nil {
		db = tx
	}
	return db.Create(transaction).Error
}

func (r *walletRepository) GetTransactions(walletID uint) ([]models.WalletTransaction, error) {
	var transactions []models.WalletTransaction
	err := r.db.Where("wallet_id = ?", walletID).Order("created_at DESC").Find(&transactions).Error
	return transactions, err
}
