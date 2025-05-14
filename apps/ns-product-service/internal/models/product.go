package models

// Review represents a product review
type Review struct {
	UserName string  `json:"userName" bson:"userName"`
	Rating   float64 `json:"rating" bson:"rating"`
	Comment  string  `json:"comment" bson:"comment"`
}

// Specifications represents product specifications as key-value pairs
type Specifications map[string]string

// Product represents a product in the database
type Product struct {
	ID              int            `json:"id" bson:"id"`
	Name            string         `json:"name" bson:"name"`
	Price           float64        `json:"price" bson:"price"`
	Image           string         `json:"image" bson:"image"`
	Description     string         `json:"description" bson:"description"`
	CategoryID      int            `json:"categoryId" bson:"categoryId"`
	Featured        bool           `json:"featured,omitempty" bson:"featured,omitempty"`
	FullDescription string         `json:"fullDescription,omitempty" bson:"fullDescription,omitempty"`
	Rating          float64        `json:"rating,omitempty" bson:"rating,omitempty"`
	ReviewCount     int            `json:"reviewCount,omitempty" bson:"reviewCount,omitempty"`
	Specifications  Specifications `json:"specifications,omitempty" bson:"specifications,omitempty"`
	Reviews         []Review       `json:"reviews,omitempty" bson:"reviews,omitempty"`
}

// Category represents a product category
type Category struct {
	ID   int    `json:"id" bson:"id"`
	Name string `json:"name" bson:"name"`
}
