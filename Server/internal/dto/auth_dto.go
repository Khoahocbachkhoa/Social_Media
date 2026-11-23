package dto

import "webapp/internal/model"

type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=50"`
	Email    string `json:"email" binding:"required,email,max=100"`
	Password string `json:"password" binding:"required,min=6,max=72"`
	FullName string `json:"full_name" binding:"required,min=1,max=100"`
}

type LoginRequest struct {
	Account  string `json:"account" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type UserResponse struct {
	ID       int     `json:"id"`
	Username string  `json:"username"`
	Email    string  `json:"email"`
	FullName string  `json:"full_name"`
	Avatar   *string `json:"avatar,omitempty"`
	Bio      *string `json:"bio,omitempty"`
}

type AuthResponse struct {
	Message string       `json:"message"`
	Token   string       `json:"token"`
	User    UserResponse `json:"user"`
}

func ToUserResponse(u *model.User) UserResponse {
	return UserResponse{
		ID:       u.ID,
		Username: u.Username,
		Email:    u.Email,
		FullName: u.FullName,
		Avatar:   u.Avatar,
		Bio:      u.Bio,
	}
}
