package config

import (
	"os"
)

// Config represents the application configuration
type Config struct {
	Port       string
	MongoDBURI string
}

// Load loads configuration from environment variables
func Load() *Config {
	return &Config{
		Port:       getEnvWithDefault("PORT", "8080"),
		MongoDBURI: getEnvWithDefault("MONGODB_URI", "mongodb://localhost:27017"),
	}
}

// getEnvWithDefault gets an environment variable or returns a default value
func getEnvWithDefault(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}
