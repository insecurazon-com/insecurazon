package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/insecurazon/ns-product-service/internal/repository"
)

// ProductHandler contains handlers for product-related endpoints
type ProductHandler struct {
	repo *repository.ProductRepository
}

// NewProductHandler creates a new ProductHandler
func NewProductHandler(repo *repository.ProductRepository) *ProductHandler {
	return &ProductHandler{repo: repo}
}

// GetAllProducts returns all products
func (h *ProductHandler) GetAllProducts(w http.ResponseWriter, r *http.Request) {
	products, err := h.repo.GetAllProducts()
	if err != nil {
		log.Printf("Error getting products: %v", err)
		http.Error(w, "Failed to get products", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(products)
}

// GetProductByID returns a product by ID
func (h *ProductHandler) GetProductByID(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	idStr := vars["id"]

	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid product ID", http.StatusBadRequest)
		return
	}

	product, err := h.repo.GetProductByID(id)
	if err != nil {
		log.Printf("Error getting product %d: %v", id, err)
		http.Error(w, "Product not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(product)
}

// GetAllCategories returns all product categories
func (h *ProductHandler) GetAllCategories(w http.ResponseWriter, r *http.Request) {
	categories, err := h.repo.GetAllCategories()
	if err != nil {
		log.Printf("Error getting categories: %v", err)
		http.Error(w, "Failed to get categories", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(categories)
}

// RegisterRoutes registers the product routes
func (h *ProductHandler) RegisterRoutes(r *mux.Router) {
	r.HandleFunc("/products", h.GetAllProducts).Methods("GET")
	r.HandleFunc("/products/{id}", h.GetProductByID).Methods("GET")
	r.HandleFunc("/products/categories", h.GetAllCategories).Methods("GET")
}
