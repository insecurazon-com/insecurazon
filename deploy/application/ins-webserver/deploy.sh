#!/bin/bash
set -e

LAMBDA_FUNCTION_NAME="ins-webserver"
DEPLOYMENT_PACKAGE="function.zip"
TEMP_DIR="lambda_deployment_temp"

# Store the original directory
ORIGINAL_DIR=$(pwd)

# Create a temporary directory for packaging
echo "Creating temporary directory for packaging..."
mkdir -p $TEMP_DIR
rm -rf $TEMP_DIR/*

# Copy package.json and install production dependencies
echo "Installing production dependencies..."
cp apps/ins-webserver/package.json $TEMP_DIR/
cd $TEMP_DIR
npm install --production
cd $ORIGINAL_DIR

# Copy compiled code to the deployment directory
echo "Copying compiled code..."
cp -r apps/ins-webserver/dist/* $TEMP_DIR/

# Create deployment package
echo "Creating deployment package..."
cd $TEMP_DIR
zip -r $ORIGINAL_DIR/$DEPLOYMENT_PACKAGE .

# Return to the original directory
cd $ORIGINAL_DIR

echo "Deploying to Lambda function: $LAMBDA_FUNCTION_NAME"
aws lambda update-function-code \
  --function-name $LAMBDA_FUNCTION_NAME \
  --zip-file fileb://$DEPLOYMENT_PACKAGE

echo "Deployment completed successfully!"

# Clean up
rm $DEPLOYMENT_PACKAGE
rm -rf $TEMP_DIR 