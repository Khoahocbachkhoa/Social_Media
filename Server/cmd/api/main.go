package main

import (
	"log"
	"net/http"

	"webapp/internal/config"
	"webapp/internal/database"
	"webapp/internal/handler"
	"webapp/internal/middleware"
	"webapp/internal/repository"
	"webapp/internal/service"

	"github.com/gin-gonic/gin"
)

func main() {
	// Load .env file
	cfg := config.Load()

	pool, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Cannot connect to database: %v", err)
	}
	defer pool.Close()

	userRepo := repository.NewUserRepository(pool)

	authService := service.NewAuthService(userRepo, cfg)

	authHandler := handler.NewAuthHandler(authService)

	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(middleware.Logger())
	r.Use(middleware.CORS(cfg.FrontendURL))

	r.GET("/health", func(c *gin.Context) {
		// Check for database
		if err := pool.Ping(c.Request.Context()); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "unavailable"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	api := r.Group("/api")
	{
		authRoutes := api.Group("/auth")
		{
			authRoutes.POST("/login", authHandler.Login)
			authRoutes.POST("/register", authHandler.Register)
			authRoutes.GET("/me", middleware.Auth(cfg.JWTSecret), authHandler.Me)
		}
	}

	addr := ":8000"

	log.Printf("server listening on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("server failed: %v", err)
	}
}
