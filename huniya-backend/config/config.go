package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	Port           string
	GinMode        string
	DBHost         string
	DBPort         string
	DBUser         string
	DBPassword     string
	DBName         string
	DBSSLMode      string
	JWTSecret      string
	JWTExpireHours int
	UploadDir      string
	MaxUploadMB    int64
}

var AppConfig *Config

func LoadConfig() *Config {
	if err := godotenv.Load(); err != nil {
		log.Println("Info: File .env tidak ditemukan, menggunakan environment variable sistem")
	}

	expireHours, err := strconv.Atoi(getEnv("JWT_EXPIRE_HOURS", "72"))
	if err != nil {
		expireHours = 72
	}

	maxUploadMB, err := strconv.ParseInt(getEnv("MAX_UPLOAD_SIZE_MB", "2"), 10, 64)
	if err != nil {
		maxUploadMB = 2
	}

	AppConfig = &Config{
		Port:           getEnv("PORT", "8080"),
		GinMode:        getEnv("GIN_MODE", "debug"),
		DBHost:         getEnv("DB_HOST", "localhost"),
		DBPort:         getEnv("DB_PORT", "5432"),
		DBUser:         getEnv("DB_USER", "postgres"),
		DBPassword:     getEnv("DB_PASSWORD", "postgres"),
		DBName:         getEnv("DB_NAME", "huniya_db"),
		DBSSLMode:      getEnv("DB_SSLMODE", "disable"),
		JWTSecret:      getEnv("JWT_SECRET", "huniya_super_secret_jwt_key_2026"),
		JWTExpireHours: expireHours,
		UploadDir:      getEnv("UPLOAD_DIR", "./uploads"),
		MaxUploadMB:    maxUploadMB,
	}

	return AppConfig
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists && value != "" {
		return value
	}
	return fallback
}
