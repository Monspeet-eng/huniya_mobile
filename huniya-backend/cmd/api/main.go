package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"huniya-backend/config"
	"huniya-backend/internal/handlers"
	"huniya-backend/internal/middlewares"
	"huniya-backend/internal/models"
	"huniya-backend/internal/repositories"
	"huniya-backend/internal/services"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.LoadConfig()
	db := config.ConnectDatabase(cfg)

	if err := os.MkdirAll(cfg.UploadDir, os.ModePerm); err != nil {
		log.Fatalf("Gagal menyiapkan folder uploads: %v", err)
	}

	gin.SetMode(cfg.GinMode)
	r := gin.Default()

	// Batas ukuran memori multipart form (15 MB)
	r.MaxMultipartMemory = 15 << 20

	// Global Middlewares
	r.Use(middlewares.CORSMiddleware())

	// Sajikan file gambar properti secara statis
	r.Static("/uploads", cfg.UploadDir)
	r.StaticFile("/swagger/doc.json", "./docs/swagger.json")

	// Healthcheck
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "huniya-backend",
			"version": "1.0.0",
		})
	})

	// Dependency Injection (Repository -> Service -> Handler)
	userRepo := repositories.NewUserRepository(db)
	propRepo := repositories.NewPropertyRepository(db)
	walletRepo := repositories.NewWalletRepository(db)
	rentalRepo := repositories.NewRentalRepository(db)
	boostRepo := repositories.NewBoostRepository(db)

	authService := services.NewAuthService(userRepo)
	propService := services.NewPropertyService(propRepo)
	walletService := services.NewWalletService(walletRepo)
	rentalService := services.NewRentalService(rentalRepo, propRepo, walletService)
	boostService := services.NewBoostService(boostRepo, propRepo, walletService)

	authHandler := handlers.NewAuthHandler(authService)
	propHandler := handlers.NewPropertyHandler(propService)
	walletHandler := handlers.NewWalletHandler(walletService)
	rentalHandler := handlers.NewRentalHandler(rentalService)
	boostHandler := handlers.NewBoostHandler(boostService)

	// Routing API v1 sesuai Kontrak Bagian 6 PRD
	api := r.Group("/api/v1")
	{
		// 6.1 Modul Autentikasi
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.GET("/me", middlewares.AuthMiddleware(), authHandler.Me)
		}

		// 6.2 Modul Pencarian & Eksplorasi (User & Public)
		api.GET("/properties", propHandler.GetProperties)
		api.GET("/properties/recommended", boostHandler.GetBoostedRecommendations)

		protected := api.Group("/")
		protected.Use(middlewares.AuthMiddleware())
		{
			// Modul Wallet (Semua pengguna berotentikasi)
			wallet := protected.Group("/wallet")
			{
				wallet.GET("", walletHandler.GetWallet)
				wallet.POST("/topup", walletHandler.TopUp)
				wallet.GET("/transactions", walletHandler.GetTransactions)
			}

			// Modul Sewa & Pengingat Jatuh Tempo (Role User)
			userRentals := protected.Group("/rentals")
			userRentals.Use(middlewares.RoleMiddleware(models.RoleUser))
			{
				userRentals.GET("", rentalHandler.GetUserRentals)
				userRentals.POST("", rentalHandler.CreateRental)
				userRentals.POST("/:id/pay", rentalHandler.PayRent)
				userRentals.GET("/reminders", rentalHandler.GetDueReminders)
			}

			protected.GET("/properties/nearby", middlewares.RoleMiddleware(models.RoleUser), propHandler.GetNearbyProperties)
			protected.GET("/properties/:id", middlewares.RoleMiddleware(models.RoleUser, models.RoleOwner), propHandler.GetPropertyDetail)

			// Wishlist khusus role user
			wishlists := protected.Group("/wishlists")
			wishlists.Use(middlewares.RoleMiddleware(models.RoleUser))
			{
				wishlists.GET("", propHandler.GetWishlists)
				wishlists.POST("/:property_id", propHandler.ToggleWishlist)
			}

			// 6.3 Modul Manajemen Properti khusus role owner
			owner := protected.Group("/owner")
			owner.Use(middlewares.RoleMiddleware(models.RoleOwner))
			{
				owner.GET("/properties", propHandler.GetOwnerProperties)
				owner.POST("/properties", propHandler.CreateProperty)
				owner.PUT("/properties/:id", propHandler.UpdateProperty)
				owner.PATCH("/properties/:id/availability", propHandler.UpdateAvailability)
				owner.DELETE("/properties/:id", propHandler.DeleteProperty)
				owner.GET("/rentals", rentalHandler.GetOwnerRentals)
				owner.POST("/properties/:id/boost", boostHandler.PurchaseBoost)
				owner.GET("/properties/:id/boost", boostHandler.GetPropertyBoost)
			}
		}
	}

	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("Huniya Backend API berjalan di http://localhost%s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("Gagal menjalankan server: %v", err)
	}
}
