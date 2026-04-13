# Cloud Patterns Implementation

## Rate Limiting Pattern
- **Endpoint:** POST /vote
- **Limit:** 5 requests per minute
- **Response:** HTTP 429 when exceeded

## Circuit Breaker Pattern
- **Endpoint:** GET /result
- **Timeout:** 2 seconds
- **Response:** HTTP 504 on timeout

## API Gateway Pattern
- Single entry point for all microservices
- Centralized routing and pattern enforcement