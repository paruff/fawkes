# Getting Started

This guide will help you get started with the sample-nodejs-app service.

## Installation

### Local Development

1. **Clone the repository**

```bash
git clone <repository-url>
cd sample-nodejs-app
```

2. **Install dependencies**

```bash
# Install dependencies
npm install
```

3. **Configure environment**

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your configuration
```

4. **Run the service**

```bash
# Development mode with auto-reload
npm run dev

# Or production mode
npm start
```

## Testing

### Run Unit Tests

```bash
npm test
```

### Run with Coverage

```bash
npm run test:coverage
```

### Linting

```bash
# Run ESLint
npm run lint

# Fix linting issues automatically
npm run lint:fix

# Run type checking (if using TypeScript)
npm run type-check
```

## Deployment

This service is automatically deployed via GitOps using ArgoCD when changes are merged to the main branch.

### CI/CD Pipeline

1. **Build**: Code is built and unit tests are executed
2. **Security Scan**: SonarQube and Trivy scans are performed
3. **Package**: Docker image is built and pushed to Harbor
4. **Deploy**: ArgoCD syncs the changes to the target environment

## Next Steps

- [API Reference](api.md) - Learn about the available endpoints
- [Development](development.md) - Contribution guidelines
