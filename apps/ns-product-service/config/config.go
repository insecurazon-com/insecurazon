package config

import (
	"encoding/json"
	"os"
)

// Config represents the application configuration
type Config struct {
	Port       string
	MongoDBURI string
}

// SecretData represents the structure of the secret from AWS Secrets Manager
type SecretData struct {
	ConnectionString string `json:"connection_string"`
	DBRoles          []struct {
		DB   string `json:"db"`
		Role string `json:"role"`
	} `json:"db_roles"`
	Password string `json:"password"`
	Username string `json:"username"`
}

// Load loads configuration from environment variables
func Load() *Config {
	// First check if we have a direct URI
	mongoURI := os.Getenv("MONGODB_URI")

	// If no direct URI, check for secret-based connection string
	if mongoURI == "" {
		// Check if we have a secret file path (CSI driver mounted secret)
		secretPath := os.Getenv("MONGODB_SECRET_PATH")
		if secretPath != "" {
			// Read the secret file
			if data, err := os.ReadFile(secretPath); err == nil {
				// Try to parse as JSON first
				var secretData SecretData
				if err := json.Unmarshal(data, &secretData); err == nil {
					// If JSON parsing succeeds, use the connection_string field
					mongoURI = secretData.ConnectionString
				} else {
					// If JSON parsing fails, use the raw string (backward compatibility)
					mongoURI = string(data)
				}
			}
		}
	}

	// If still no URI, use default
	if mongoURI == "" {
		mongoURI = "mongodb://localhost:27017"
	}

	return &Config{
		Port:       getEnvWithDefault("PORT", "8080"),
		MongoDBURI: mongoURI,
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
