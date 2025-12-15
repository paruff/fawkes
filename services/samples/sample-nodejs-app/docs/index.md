# ${{ values.name }}

## Overview

${{ values.description }}

## Quick Start

This service is part of the Fawkes platform and follows the golden path for Node.js microservices.

### Prerequisites

- Node.js 18+ and npm
- Docker
- Access to the Fawkes platform

### Running Locally

```bash
# Install dependencies
npm install

# Run the service
npm start
```

The service will be available at `http://localhost:${{ values.port }}`.

## Architecture

This service is built using:

- **Express**: Fast, unopinionated web framework for Node.js
- **TypeScript**: Typed superset of JavaScript for better code quality
- **OpenTelemetry**: Distributed tracing and observability

## Features

- RESTful API with OpenAPI documentation
- Health check endpoints
- Prometheus metrics
- Distributed tracing with OpenTelemetry
- Structured logging

## Documentation

- [Getting Started](getting-started.md) - Setup and installation guide
- [API Reference](api.md) - API endpoints and usage
- [Development](development.md) - Development guidelines

## Support

For issues and questions:

- Create an issue in the GitHub repository
- Contact the platform team via Backstage
- Check the [Fawkes documentation](https://backstage.fawkes.idp/docs)

## Owner

**Team**: ${{ values.owner }}
