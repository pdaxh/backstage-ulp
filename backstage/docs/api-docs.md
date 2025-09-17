# API Documentation

This section provides comprehensive API documentation for all services in the ULP platform.

## Overview

The ULP platform exposes several APIs for different purposes:

- **Service APIs**: Core business logic and functionality
- **Platform APIs**: Infrastructure and platform management
- **Integration APIs**: Third-party service integrations
- **Monitoring APIs**: Health checks and metrics

## API Standards

### Authentication

All APIs use OAuth 2.0 with JWT tokens:

```bash
Authorization: Bearer <your-jwt-token>
```

### Response Format

All APIs return responses in JSON format:

```json
{
  "data": {},
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  },
  "errors": []
}
```

### Error Handling

APIs return appropriate HTTP status codes:

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Service APIs

### Python App API

**Base URL**: `http://localhost:8080`

#### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Welcome message |
| GET | `/health` | Health check |
| GET | `/api/v1/status` | Service status |
| POST | `/api/v1/data` | Create data |

#### Health Check

```bash
curl -X GET http://localhost:8080/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z",
  "version": "1.0.0"
}
```

## Platform APIs

### Backstage API

**Base URL**: `http://localhost:7007/api`

#### Catalog API

- `GET /catalog/entities` - List all entities
- `GET /catalog/entities/{kind}/{namespace}/{name}` - Get specific entity
- `POST /catalog/entities` - Create entity

#### Search API

- `GET /search/query` - Search across all entities
- `GET /search/query/{query}` - Search with specific query

## Integration APIs

### GitHub Integration

- `GET /github/repos` - List repositories
- `GET /github/repos/{owner}/{repo}` - Get repository details
- `POST /github/webhooks` - GitHub webhook endpoint

### Kubernetes Integration

- `GET /k8s/clusters` - List available clusters
- `GET /k8s/namespaces` - List namespaces
- `GET /k8s/pods` - List pods

## Monitoring APIs

### Health Checks

All services expose health check endpoints:

- **Liveness**: `/healthz` - Service is running
- **Readiness**: `/ready` - Service is ready to serve traffic

### Metrics

Services expose Prometheus-compatible metrics at `/metrics`:

- Request count and duration
- Error rates
- Resource utilization
- Custom business metrics

## API Testing

### Using curl

```bash
# Health check
curl -X GET http://localhost:8080/health

# With authentication
curl -X GET http://localhost:8080/api/v1/status \
  -H "Authorization: Bearer <token>"
```

### Using Postman

Import the API collection from the [API Collection](./api-collection.json) file.

### Using Swagger UI

Interactive API documentation is available at:
- Python App: `http://localhost:8080/docs`
- Backstage: `http://localhost:7007/api-docs`

## Rate Limiting

APIs implement rate limiting to ensure fair usage:

- **Default**: 100 requests per minute per IP
- **Authenticated**: 1000 requests per minute per user
- **Burst**: Up to 200 requests in a single minute

Rate limit headers are included in responses:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## SDKs and Libraries

### Python SDK

```python
from ulp_sdk import ULPClient

client = ULPClient(api_key="your-api-key")
status = client.health.check()
```

### JavaScript SDK

```javascript
import { ULPClient } from '@ulp/sdk';

const client = new ULPClient({ apiKey: 'your-api-key' });
const status = await client.health.check();
```

## Changelog

### v1.0.0 (2024-01-01)
- Initial API release
- Basic CRUD operations
- Health check endpoints

### v1.1.0 (2024-01-15)
- Added authentication
- Rate limiting implementation
- Enhanced error handling

## Support

For API support:
- Check the [Troubleshooting Guide](./troubleshooting.md)
- Contact the platform team
- Submit issues via GitHub
