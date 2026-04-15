# Cloud Patterns Implementation

## Event-Driven Pattern (Kafka)
- **Flow:** vote -> kafka topic `votes` -> worker -> postgresql
- **Purpose:** decouple vote ingestion from persistence processing

## Rate Limiting Pattern
- **Endpoint:** POST /vote
- **Limit:** 5 requests per minute
- **Response:** HTTP 429 when exceeded

## Circuit Breaker Pattern
- **Endpoint:** GET /result
- **Timeout:** 2 seconds
- **Response:** HTTP 504 on timeout

## Implementation note
- API Gateway pattern is not currently implemented in the deployed state.
- Pub/Sub Retry + DLQ exists as Terraform module capability, but is currently disabled in `terraform/live/prod/terraform.tfvars`.