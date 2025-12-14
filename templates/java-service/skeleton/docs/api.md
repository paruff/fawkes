# API Reference

## Base URL

- **Local Development**: `http://localhost:${{ values.port }}`
- **Development**: `https://${{ values.name }}.dev.fawkes.idp`
- **Production**: `https://${{ values.name }}.fawkes.idp`

## Authentication

API authentication details will be added here based on your requirements.

## Health Check Endpoints

### GET /health

Health check endpoint for the service.

**Response**

```json
{
  "status": "healthy",
  "timestamp": "2024-12-14T10:00:00Z"
}
```

**Status Codes**

- `200 OK`: Service is healthy
- `503 Service Unavailable`: Service is unhealthy

### GET /metrics

Prometheus metrics endpoint.

**Response**

Returns metrics in Prometheus format for scraping.

## API Endpoints

### GET /

Welcome endpoint.

**Response**

```json
{
  "message": "Welcome to ${{ values.name }}",
  "version": "1.0.0"
}
```

## OpenAPI Documentation

Interactive API documentation is available at:

- Swagger UI: `http://localhost:${{ values.port }}/docs`
- ReDoc: `http://localhost:${{ values.port }}/redoc`
- OpenAPI JSON: `http://localhost:${{ values.port }}/openapi.json`

## Error Responses

All error responses follow this format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  }
}
```

### Common Status Codes

- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error
