package services

import (
	"errors"
	"fmt"
	"strings"

	"huniya-backend/internal/dto"
	"huniya-backend/internal/models"
	"huniya-backend/internal/repositories"
	"huniya-backend/pkg/utils"
)

type AuthService interface {
	Register(req dto.RegisterRequest) (*dto.AuthResponse, error)
	Login(req dto.LoginRequest) (*dto.AuthResponse, error)
	GetCurrentUser(userID uint) (*dto.UserResponse, error)
}

type authService struct {
	userRepo repositories.UserRepository
}

func NewAuthService(userRepo repositories.UserRepository) AuthService {
	return &authService{userRepo: userRepo}
}

func (s *authService) Register(req dto.RegisterRequest) (*dto.AuthResponse, error) {
	email := strings.ToLower(strings.TrimSpace(req.Email))
	if existing, _ := s.userRepo.FindByEmail(email); existing != nil {
		return nil, errors.New("email sudah terdaftar, silakan gunakan email lain")
	}

	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		return nil, errors.New("gagal memproses keamanan password")
	}

	phone := normalizePhone(req.Phone)

	user := &models.User{
		Name:         strings.TrimSpace(req.Name),
		Email:        email,
		PasswordHash: hashedPassword,
		Phone:        phone,
		Role:         req.Role,
	}

	if err := s.userRepo.Create(user); err != nil {
		return nil, errors.New("gagal menyimpan data pengguna")
	}

	token, err := utils.GenerateToken(user.ID, user.Email, user.Role)
	if err != nil {
		return nil, errors.New("gagal membuat token autentikasi")
	}

	return &dto.AuthResponse{
		AccessToken: token,
		User: dto.UserResponse{
			ID:    fmt.Sprintf("%d", user.ID),
			Name:  user.Name,
			Email: user.Email,
			Role:  user.Role,
			Phone: user.Phone,
		},
	}, nil
}

func (s *authService) Login(req dto.LoginRequest) (*dto.AuthResponse, error) {
	email := strings.ToLower(strings.TrimSpace(req.Email))
	user, err := s.userRepo.FindByEmail(email)
	if err != nil {
		return nil, errors.New("email atau password salah")
	}

	if !utils.CheckPasswordHash(req.Password, user.PasswordHash) {
		return nil, errors.New("email atau password salah")
	}

	token, err := utils.GenerateToken(user.ID, user.Email, user.Role)
	if err != nil {
		return nil, errors.New("gagal membuat token autentikasi")
	}

	return &dto.AuthResponse{
		AccessToken: token,
		User: dto.UserResponse{
			ID:    fmt.Sprintf("%d", user.ID),
			Name:  user.Name,
			Email: user.Email,
			Role:  user.Role,
			Phone: user.Phone,
		},
	}, nil
}

func (s *authService) GetCurrentUser(userID uint) (*dto.UserResponse, error) {
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return nil, errors.New("pengguna tidak ditemukan")
	}

	return &dto.UserResponse{
		ID:    fmt.Sprintf("%d", user.ID),
		Name:  user.Name,
		Email: user.Email,
		Role:  user.Role,
		Phone: user.Phone,
	}, nil
}

func normalizePhone(phone string) string {
	cleaned := strings.TrimSpace(phone)
	cleaned = strings.ReplaceAll(cleaned, " ", "")
	cleaned = strings.ReplaceAll(cleaned, "-", "")
	cleaned = strings.TrimPrefix(cleaned, "+")
	if strings.HasPrefix(cleaned, "08") {
		cleaned = "628" + strings.TrimPrefix(cleaned, "08")
	}
	return cleaned
}
