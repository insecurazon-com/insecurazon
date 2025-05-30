#!/bin/bash

# Script to initialize MongoDB with sample data

# Default MongoDB URI - update with authentication credentials
MONGO_URI=${MONGODB_URI:-"mongodb://root:example@localhost:27017/insecurazon?authSource=admin"}

echo "Seeding MongoDB with sample data..."
echo "Using connection: $MONGO_URI"

# Run the MongoDB initialization script
mongosh "$MONGO_URI" --file ./scripts/init-mongo.js

if [ $? -eq 0 ]; then
  echo "Database seeding completed successfully!"
else
  echo "Error: Database seeding failed."
  exit 1
fi 