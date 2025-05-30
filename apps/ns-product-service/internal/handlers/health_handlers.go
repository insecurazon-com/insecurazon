package handlers

import (
	"net/http"

	"github.com/gorilla/mux"
)

// HealthHandler contains handlers for health check endpoints
type HealthHandler struct{}

// NewHealthHandler creates a new health check handler
func NewHealthHandler() *HealthHandler {
	return &HealthHandler{}
}

// LivenessCheck responds to Kubernetes liveness probe
func (h *HealthHandler) LivenessCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

// ReadinessCheck responds to Kubernetes readiness probe
func (h *HealthHandler) ReadinessCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

// RegisterRoutes registers the health check routes
func (h *HealthHandler) RegisterRoutes(r *mux.Router) {
	r.HandleFunc("/health/live", h.LivenessCheck).Methods("GET")
	r.HandleFunc("/health/ready", h.ReadinessCheck).Methods("GET")
}
