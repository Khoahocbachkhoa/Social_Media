package model

type User struct {
	ID       int     `json:"id"`
	Username string  `json:"username"`
	Email    string  `json:"email"`
	Password string  `json:"-"`
	FullName string  `json:"full_name"`
	Avatar   *string `json:"avatar,omitempty"`
	Bio      *string `json:"bio,omitempty"`
}
