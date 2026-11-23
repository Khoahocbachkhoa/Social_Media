package repository

import (
	"context"
	"errors"
	"strings"

	"webapp/internal/model"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrUserNotFound   = errors.New("user not found")
	ErrEmailExists    = errors.New("email already exists")
	ErrUsernameExists = errors.New("username already exists")
)

type UserRepository interface {
	Create(ctx context.Context, user *model.User) error
	FindByEmail(ctx context.Context, email string) (*model.User, error)
	FindByUsername(ctx context.Context, username string) (*model.User, error)
	FindByAccount(ctx context.Context, account string) (*model.User, error)
}

type userRepository struct {
	pool *pgxpool.Pool
}

func NewUserRepository(pool *pgxpool.Pool) *userRepository {
	return &userRepository{pool: pool}
}

func (r *userRepository) Create(ctx context.Context, user *model.User) error {
	query := `
		INSERT INTO users (username, email, password, full_name)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`
	err := r.pool.
		QueryRow(ctx, query, user.Username, user.Email, user.Password, user.FullName).
		Scan(&user.ID)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			if strings.Contains(pgErr.ConstraintName, "email") {
				return ErrEmailExists
			}
			if strings.Contains(pgErr.ConstraintName, "username") {
				return ErrUsernameExists
			}
		}
		return err
	}
	return nil
}

func (r *userRepository) FindByEmail(ctx context.Context, email string) (*model.User, error) {
	return r.findOne(ctx,
		"SELECT id, username, email, password, full_name, avatar, bio FROM users WHERE email=$1", email)
}

func (r *userRepository) FindByUsername(ctx context.Context, username string) (*model.User, error) {
	return r.findOne(ctx,
		"SELECT id, username, email, password, full_name, avatar, bio FROM users WHERE username=$1", username)
}

func (r *userRepository) FindByAccount(ctx context.Context, account string) (*model.User, error) {
	return r.findOne(ctx,
		"SELECT id, username, email, password, full_name, avatar, bio FROM users WHERE email=$1 OR username=$1", account)
}

func (r *userRepository) findOne(ctx context.Context, query string, arg any) (*model.User, error) {
	var u model.User
	err := r.pool.QueryRow(ctx, query, arg).Scan(
		&u.ID, &u.Username, &u.Email, &u.Password, &u.FullName, &u.Avatar, &u.Bio,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}
