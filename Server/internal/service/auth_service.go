package service

import (
	"context"
	"errors"
	"strings"

	"webapp/internal/config"
	"webapp/internal/dto"
	"webapp/internal/model"
	"webapp/internal/repository"
	"webapp/pkg/hash"
	"webapp/pkg/jwt"
)

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrEmailExists        = errors.New("email already exists")
	ErrUsernameExists     = errors.New("username already exists")
)

type AuthService struct {
	repo repository.UserRepository
	cfg  *config.Config
}

func NewAuthService(repo repository.UserRepository, cfg *config.Config) *AuthService {
	return &AuthService{repo: repo, cfg: cfg}
}

func (s *AuthService) Register(ctx context.Context, req dto.RegisterRequest) (*dto.AuthResponse, error) {
	hashed, err := hash.Password(req.Password)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		Username: strings.TrimSpace(req.Username),
		Email:    strings.TrimSpace(strings.ToLower(req.Email)),
		Password: hashed,
		FullName: strings.TrimSpace(req.FullName),
	}

	if err := s.repo.Create(ctx, user); err != nil {
		if errors.Is(err, repository.ErrEmailExists) {
			return nil, ErrEmailExists
		}
		if errors.Is(err, repository.ErrUsernameExists) {
			return nil, ErrUsernameExists
		}
		return nil, err
	}

	token, err := jwt.GenerateToken(user.ID, user.Username, s.cfg.JWTSecret, s.cfg.JWTExpireH)
	if err != nil {
		return nil, err
	}

	return &dto.AuthResponse{
		Message: "Register successfully",
		Token:   token,
		User:    dto.ToUserResponse(user),
	}, nil
}

func (s *AuthService) Login(ctx context.Context, req dto.LoginRequest) (*dto.AuthResponse, error) {
	account := strings.TrimSpace(req.Account)
	user, err := s.repo.FindByAccount(ctx, account)
	if err != nil {
		if errors.Is(err, repository.ErrUserNotFound) {
			return nil, ErrInvalidCredentials
		}
		return nil, err
	}

	if err := hash.CheckPassword(user.Password, req.Password); err != nil {
		return nil, ErrInvalidCredentials
	}

	token, err := jwt.GenerateToken(user.ID, user.Username, s.cfg.JWTSecret, s.cfg.JWTExpireH)
	if err != nil {
		return nil, err
	}

	return &dto.AuthResponse{
		Message: "Login successfully",
		Token:   token,
		User:    dto.ToUserResponse(user),
	}, nil
}
