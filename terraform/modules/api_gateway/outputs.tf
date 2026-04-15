output "gateway_id" {
  description = "API Gateway id"
  value       = try(google_api_gateway_gateway.this[0].id, null)
}

output "gateway_default_hostname" {
  description = "Default hostname exposed by API Gateway"
  value       = try(google_api_gateway_gateway.this[0].default_hostname, null)
}
