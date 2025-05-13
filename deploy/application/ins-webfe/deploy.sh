#!/bin/bash

set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <s3-bucket-name>"
  exit 1
fi

S3_BUCKET=$1
SOURCE_DIR="apps/ins-webfe/dist"

echo "Deploying ins-webfe to S3 bucket: $S3_BUCKET"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Source directory $SOURCE_DIR does not exist"
  exit 1
fi

# Sync to S3 bucket
echo "Syncing files to S3..."
aws s3 sync $SOURCE_DIR s3://$S3_BUCKET --delete --cache-control "max-age=3600"

echo "Deployment complete!" 