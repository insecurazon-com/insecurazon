package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"github.com/insecurazon/ns-product-service/config"
	"github.com/insecurazon/ns-product-service/internal/handlers"
	"github.com/insecurazon/ns-product-service/internal/repository"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env file if exists
	godotenv.Load()

	// Load configuration
	cfg := config.Load()

	// Initialize database repository
	repo, err := repository.NewProductRepository()
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer repo.Close()

	// Seed initial data
	if err := repo.SeedProductsIfEmpty(); err != nil {
		log.Printf("Warning: Failed to seed initial data: %v", err)
	}

	// Create router
	r := mux.NewRouter()

	// Create and register product handlers
	productHandler := handlers.NewProductHandler(repo)
	productHandler.RegisterRoutes(r)

	// Create and register health check handlers
	healthHandler := handlers.NewHealthHandler()
	healthHandler.RegisterRoutes(r)

	// Add middleware
	r.Use(handlers.LoggingMiddleware)
	r.Use(handlers.CORSMiddleware)

	// Create server
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on port %s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shut down the server
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	<-c

	log.Println("Server shutting down...")
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited properly")
}
