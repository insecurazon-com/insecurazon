# InsecurAzon Web Frontend

A demo e-commerce web application built with Vue.js and Vuetify, serving as the frontend for the InsecurAzon application.

## Overview

This demo e-commerce platform is designed to showcase a modern web application architecture, with intentional security vulnerabilities for threat modeling. The application includes:

- Product browsing and search
- Product details view
- Shopping cart functionality
- Checkout process
- Order confirmation

## Technology Stack

- Vue.js 3 - Frontend framework
- Vuetify 3 - Material Design component library
- Vue Router - Client-side routing
- Axios - API requests

## Development

### Prerequisites

- Node.js 16+
- PNPM package manager

### Setup

Install dependencies:

```bash
pnpm install
```

### Development Server

Start the development server:

```bash
pnpm dev
```

The application will be available at http://localhost:3000 (or another port if 3000 is in use).

### Build

Build the application for production:

```bash
pnpm build
```

### Preview Production Build

Preview the production build:

```bash
pnpm preview
```

## Project Structure

```
ins-webfe/
├── public/           # Static assets
│   ├── assets/       # Images, fonts, etc.
│   ├── components/   # Vue components
│   ├── services/     # API services
│   ├── views/        # Page components
│   ├── App.vue       # Root component
│   └── main.js       # Application entry point
├── index.html        # HTML template
└── vite.config.js    # Vite configuration
```

## Backend Integration

The frontend communicates with backend services through RESTful APIs. The API endpoints are defined in the `src/services/api.js` file.

## Note on Security

This application is intentionally built with security vulnerabilities for educational purposes as part of a security threat modeling exercise. Do not use this code in production environments without a thorough security review.
