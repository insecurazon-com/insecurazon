# ins-webfe Deployment

This directory contains scripts for deploying the ins-webfe Vue application to AWS S3 for static web hosting.

## Overview

The deployment process:
1. Builds the Vue application using the turborepo build system with pnpm
2. Syncs the built artifacts to the S3 bucket configured for static website hosting
3. Invalidates the CloudFront cache to ensure the latest version is served to users

## Deployment Scripts

- `deploy.sh`: Deploys the built artifacts to the S3 bucket

## Manual Deployment

To manually deploy the ins-webfe application:

1. Build the application:
```bash
pnpm turbo run build --filter=ins-webfe
```

2. Run the deployment script:
```bash
./deploy.sh <s3-bucket-name>
```

3. Optionally invalidate CloudFront (if configured):
```bash
aws cloudfront create-invalidation --distribution-id <cloudfront-id> --paths "/*"
```

## CI/CD Deployment

The application is automatically deployed via GitHub Actions when code is pushed to the master branch. See `.github/workflows/main.yml` for the complete workflow configuration. 