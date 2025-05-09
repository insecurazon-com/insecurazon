# InsecurAzon Web Server

A serverless NestJS application that serves the Vue SPA frontend and proxies API requests to backend services for the InsecurAzon demo application.

## Overview

This application performs two main functions:

1. Serves the Vue.js SPA frontend application (static files)
2. Proxies API requests to the appropriate backend services via an API Gateway

## Architecture

- AWS Lambda function with API Gateway trigger
- NestJS framework for server-side functionality
- Express.js for handling HTTP requests
- Serverless Framework for deployment and infrastructure management

## API Proxy

The API proxy forwards requests from the frontend to the backend services via a centralized API Gateway. This follows the Backend for Frontend (BFF) pattern, which:

- Hides the backend architecture from the client
- Allows for custom API transformations specific to the frontend's needs
- Provides a centralized place for common functionality like authentication
- Reduces the number of CORS configurations needed

## Development

### Prerequisites

- Node.js 16+
- PNPM package manager
- AWS CLI (for deployment)
- Serverless Framework CLI

### Local Development

Install dependencies:

```bash
pnpm install
```

To run the application locally:

```bash
pnpm run start:dev
```

The server will be accessible at http://localhost:3000.

### Deployment

To package the application for deployment:

```bash
pnpm run serverless:package
```

To deploy to AWS:

```bash
pnpm run serverless:deploy
```

You can specify the deployment stage (dev, staging, prod):

```bash
pnpm run serverless:deploy -- --stage prod
```

## Security Considerations

As this is a demo application for security threat modeling, there are intentional security vulnerabilities included for educational purposes. In a real-world application, additional security measures would be implemented:

- Proper input validation
- Request rate limiting
- Web Application Firewall (WAF) integration
- Detailed logging and monitoring
- Enhanced error handling and sanitizing error responses

## Environment Variables

- `API_GATEWAY_URL`: URL of the API Gateway (default: https://api.insecurazon.local)
- `STATIC_FILES_PATH`: Path to the Vue.js static files (default: ../ins-webfe/dist)
- `PORT`: Port for local development (default: 3000) 