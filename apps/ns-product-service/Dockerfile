# Build stage
FROM golang:1.24.3-alpine AS builder

# Set working directory
WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/bin/product-service ./cmd

# Final stage
FROM alpine:3.19

# Add ca certificates and tzdata
RUN apk --no-cache add ca-certificates tzdata

# Create a non-root user and group
RUN addgroup -S app && adduser -S app -G app

# Set working directory
WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/bin/product-service .

# Use the non-root user
USER app

# Expose the port
EXPOSE 8080

# Run the application
CMD ["./product-service"] 