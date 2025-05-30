# Product Service

A Go microservice for managing product data, backed by MongoDB. This service provides product information to the Insecurazon web application.

## Features

- RESTful API for product data
- MongoDB for data persistence
- Docker containerization
- Kubernetes deployment

## API Endpoints

- `GET /products` - Get all products
- `GET /products/{id}` - Get a product by ID
- `GET /products/categories` - Get all product categories

## Configuration

The service is configured using environment variables:

- `PORT` - HTTP server port (default: 8080)
- `MONGODB_URI` - MongoDB connection string (default: mongodb://localhost:27017)

## Running Locally

### Prerequisites

- Go 1.19 or higher
- MongoDB running locally or accessible remotely

### Setup

1. Clone the repository
2. Set the MongoDB connection string:
   ```
   export MONGODB_URI="mongodb://localhost:27017"
   ```
3. Run the service:
   ```
   go run cmd/main.go
   ```

## Docker

### Building the Docker Image

```bash
docker build -t insecurazon/product-service:latest .
```

### Running with Docker

```bash
docker run -p 8080:8080 -e MONGODB_URI="mongodb://mongo:27017" insecurazon/product-service:latest
```

## Kubernetes Deployment

Apply the Kubernetes manifests:

```bash
kubectl apply -f k8s/deployment.yaml
```

Make sure to update the MongoDB URI secret in the manifest before applying.

## Development

### Project Structure

- `cmd/` - Application entry point
- `internal/` - Private application code
  - `models/` - Data models
  - `repository/` - Data access layer
  - `handlers/` - HTTP handlers
- `k8s/` - Kubernetes manifests 