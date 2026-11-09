package config

import (
	"fmt"
	"log"

	"huniya-backend/internal/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

func ConnectDatabase(cfg *Config) *gorm.DB {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=Asia/Jakarta",
		cfg.DBHost,
		cfg.DBUser,
		cfg.DBPassword,
		cfg.DBName,
		cfg.DBPort,
		cfg.DBSSLMode,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatalf("Gagal terhubung ke database PostgreSQL: %v", err)
	}

	// AutoMigrate skema tabel sesuai PRD
	if err := db.AutoMigrate(
		&models.User{},
		&models.Property{},
		&models.Wishlist{},
		&models.Wallet{},
		&models.WalletTransaction{},
		&models.Rental{},
		&models.RentalPayment{},
		&models.BoostAd{},
	); err != nil {
		log.Fatalf("Gagal menjalankan AutoMigrate: %v", err)
	}

	// Buat index komposit geospasial & pencarian untuk optimasi query (<500ms)
	db.Exec("CREATE INDEX IF NOT EXISTS idx_properties_lat_lng ON properties (latitude, longitude);")
	db.Exec("CREATE INDEX IF NOT EXISTS idx_properties_type_city ON properties (type, city);")
	db.Exec("CREATE UNIQUE INDEX IF NOT EXISTS idx_wishlists_user_property ON wishlists (user_id, property_id);")

	DB = db
	log.Println("Database PostgreSQL berhasil terhubung & dimigrasi")
	return db
}
