#!/bin/bash
set -e

LAMBDA_FUNCTION_NAME="ins-webserver"
DEPLOYMENT_PACKAGE="function.zip"

echo "Packaging Lambda function..."
cd apps/ins-webserver/dist
zip -r ../../../$DEPLOYMENT_PACKAGE .

echo "Deploying to Lambda function: $LAMBDA_FUNCTION_NAME"
aws lambda update-function-code \
  --function-name $LAMBDA_FUNCTION_NAME \
  --zip-file fileb://$DEPLOYMENT_PACKAGE

echo "Deployment completed successfully!" 