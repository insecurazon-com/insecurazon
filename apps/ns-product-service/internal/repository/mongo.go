package repository

import (
	"context"
	"log"
	"time"

	"github.com/insecurazon/ns-product-service/config"
	"github.com/insecurazon/ns-product-service/internal/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// MongoDB constants
const (
	databaseName   = "insecurazon"
	productsColl   = "products"
	categoriesColl = "categories"
	defaultTimeout = 10 * time.Second
)

// ProductRepository provides methods to interact with products in MongoDB
type ProductRepository struct {
	client     *mongo.Client
	database   *mongo.Database
	products   *mongo.Collection
	categories *mongo.Collection
}

// NewProductRepository creates a new MongoDB repository
func NewProductRepository() (*ProductRepository, error) {
	cfg := config.Load()
	uri := cfg.MongoDBURI

	ctx, cancel := context.WithTimeout(context.Background(), defaultTimeout)
	defer cancel()

	clientOptions := options.Client().ApplyURI(uri)
	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		return nil, err
	}

	// Check the connection
	err = client.Ping(ctx, nil)
	if err != nil {
		return nil, err
	}

	log.Println("Connected to MongoDB")
	database := client.Database(databaseName)

	return &ProductRepository{
		client:     client,
		database:   database,
		products:   database.Collection(productsColl),
		categories: database.Collection(categoriesColl),
	}, nil
}

// Close disconnects from MongoDB
func (r *ProductRepository) Close() error {
	ctx, cancel := context.WithTimeout(context.Background(), defaultTimeout)
	defer cancel()
	return r.client.Disconnect(ctx)
}

// GetAllProducts retrieves all products from the database
func (r *ProductRepository) GetAllProducts() ([]models.Product, error) {
	ctx, cancel := context.WithTimeout(context.Background(), defaultTimeout)
	defer cancel()

	var products []models.Product
	cursor, err := r.products.Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &products); err != nil {
		return nil, err
	}

	return products, nil
}

// GetProductByID retrieves a single product by ID
func (r *ProductRepository) GetProductByID(id int) (*models.Product, error) {
	ctx, cancel := context.WithTimeout(context.Background(), defaultTimeout)
	defer cancel()

	var product models.Product
	err := r.products.FindOne(ctx, bson.M{"id": id}).Decode(&product)
	if err != nil {
		return nil, err
	}

	return &product, nil
}

// GetAllCategories retrieves all product categories
func (r *ProductRepository) GetAllCategories() ([]models.Category, error) {
	ctx, cancel := context.WithTimeout(context.Background(), defaultTimeout)
	defer cancel()

	var categories []models.Category
	cursor, err := r.categories.Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &categories); err != nil {
		return nil, err
	}

	return categories, nil
}

// SeedProductsIfEmpty populates the database with initial data if empty
func (r *ProductRepository) SeedProductsIfEmpty() error {
	ctx, cancel := context.WithTimeout(context.Background(), defaultTimeout)
	defer cancel()

	// Check if products collection is empty
	count, err := r.products.CountDocuments(ctx, bson.M{})
	if err != nil {
		return err
	}

	if count > 0 {
		return nil // Collection already has data
	}

	// Sample products
	products := []interface{}{
		models.Product{
			ID:              1,
			Name:            "Smartphone X",
			Featured:        true,
			Price:           799.99,
			Image:           "https://via.placeholder.com/300?text=Smartphone+X",
			Description:     "The latest smartphone with amazing features and long battery life.",
			CategoryID:      1,
			FullDescription: "Experience the future of mobile technology with the Smartphone X. Featuring a stunning 6.5-inch OLED display, powerful octa-core processor, and advanced camera system, this smartphone delivers exceptional performance in a sleek design. With all-day battery life and fast charging capabilities, you can stay connected without interruption.",
			Rating:          4.5,
			ReviewCount:     127,
			Specifications: models.Specifications{
				"Display":   "6.5-inch OLED",
				"Processor": "Octa-core 2.8GHz",
				"RAM":       "8GB",
				"Storage":   "128GB",
				"Camera":    "12MP + 16MP dual rear, 8MP front",
				"Battery":   "4500mAh",
				"OS":        "Android 12",
			},
			Reviews: []models.Review{
				{UserName: "John D.", Rating: 5, Comment: "Best phone I've ever owned. The battery life is incredible!"},
				{UserName: "Sarah M.", Rating: 4, Comment: "Great phone, but a bit expensive."},
				{UserName: "Michael K.", Rating: 4.5, Comment: "Excellent camera quality and fast performance."},
			},
		},
		models.Product{
			ID:              2,
			Name:            "Wireless Headphones",
			Featured:        true,
			Price:           149.99,
			Image:           "https://via.placeholder.com/300?text=Wireless+Headphones",
			Description:     "Premium wireless headphones with noise cancellation.",
			CategoryID:      1,
			FullDescription: "Immerse yourself in superior sound quality with these premium wireless headphones. Featuring advanced noise cancellation technology, these headphones block out ambient noise so you can focus on your music. With cushioned ear cups and an adjustable headband, they provide exceptional comfort for extended listening sessions.",
			Rating:          4.7,
			ReviewCount:     89,
			Specifications: models.Specifications{
				"Type":               "Over-ear",
				"Connectivity":       "Bluetooth 5.0",
				"Battery Life":       "Up to 30 hours",
				"Noise Cancellation": "Active",
				"Charging":           "USB-C",
				"Weight":             "250g",
			},
			Reviews: []models.Review{
				{UserName: "Emily R.", Rating: 5, Comment: "The noise cancellation is amazing! Perfect for travel."},
				{UserName: "David T.", Rating: 4.5, Comment: "Great sound quality and comfortable to wear."},
			},
		},
		models.Product{
			ID:              3,
			Name:            "Smart Watch",
			Featured:        true,
			Price:           249.99,
			Image:           "https://via.placeholder.com/300?text=Smart+Watch",
			Description:     "Track your fitness and stay connected with this smart watch.",
			CategoryID:      1,
			FullDescription: "Stay connected and monitor your health with this feature-packed smart watch. Track your steps, heart rate, sleep quality, and more with accurate sensors. Receive notifications, answer calls, and control your music right from your wrist. With a water-resistant design and long battery life, this smart watch is perfect for an active lifestyle.",
			Rating:          4.2,
			ReviewCount:     64,
			Specifications: models.Specifications{
				"Display":          "1.4-inch AMOLED",
				"Sensors":          "Heart rate, accelerometer, GPS",
				"Battery Life":     "Up to 7 days",
				"Water Resistance": "5 ATM",
				"Connectivity":     "Bluetooth, Wi-Fi",
				"Compatibility":    "Android, iOS",
			},
			Reviews: []models.Review{
				{UserName: "Robert J.", Rating: 4, Comment: "Great fitness tracking features but battery life could be better."},
				{UserName: "Lisa M.", Rating: 5, Comment: "Love how it tracks my workouts and sleep!"},
			},
		},
		models.Product{
			ID:              4,
			Name:            "Designer T-shirt",
			Featured:        false,
			Price:           39.99,
			Image:           "https://via.placeholder.com/300?text=Designer+T-shirt",
			Description:     "Comfortable cotton t-shirt with modern design.",
			CategoryID:      2,
			FullDescription: "A very comfortable cotton t-shirt with a modern design, perfect for casual wear.",
			Rating:          4.0,
			ReviewCount:     25,
			Specifications: models.Specifications{
				"Material": "100% Cotton",
				"Fit":      "Regular",
			},
		},
		models.Product{
			ID:              5,
			Name:            "Jeans",
			Featured:        false,
			Price:           59.99,
			Image:           "https://via.placeholder.com/300?text=Jeans",
			Description:     "Classic jeans with perfect fit and durability.",
			CategoryID:      2,
			FullDescription: "Classic denim jeans that offer both style and durability. A wardrobe essential.",
			Rating:          4.3,
			ReviewCount:     40,
			Specifications: models.Specifications{
				"Material": "Denim",
				"Fit":      "Straight Leg",
			},
		},
		models.Product{
			ID:              6,
			Name:            "Coffee Maker",
			Featured:        false,
			Price:           99.99,
			Image:           "https://via.placeholder.com/300?text=Coffee+Maker",
			Description:     "Brew the perfect cup of coffee every morning.",
			CategoryID:      3,
			FullDescription: "Start your day right with this easy-to-use coffee maker. Brews a perfect cup every time.",
			Rating:          4.6,
			ReviewCount:     70,
			Specifications: models.Specifications{
				"Capacity": "12 Cups",
				"Features": "Programmable Timer, Auto Shut-off",
			},
		},
	}

	// Insert products
	_, err = r.products.InsertMany(ctx, products)
	if err != nil {
		return err
	}

	// Check if categories collection is empty
	countCat, err := r.categories.CountDocuments(ctx, bson.M{})
	if err != nil {
		return err
	}

	if countCat > 0 {
		return nil // Collection already has data
	}

	// Sample categories
	categories := []interface{}{
		models.Category{ID: 1, Name: "Electronics"},
		models.Category{ID: 2, Name: "Clothing"},
		models.Category{ID: 3, Name: "Home & Garden"},
		models.Category{ID: 4, Name: "Books"},
		models.Category{ID: 5, Name: "Toys"},
	}

	// Insert categories
	_, err = r.categories.InsertMany(ctx, categories)
	return err
}
