#!/bin/bash
set -e

LAMBDA_FUNCTION_NAME="ins-webserver"
DEPLOYMENT_PACKAGE="function.zip"

# Store the original directory
ORIGINAL_DIR=$(pwd)

echo "Packaging Lambda function..."
cd apps/ins-webserver/dist
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