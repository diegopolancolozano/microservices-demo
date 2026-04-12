output "gateway_default_hostname" {
  description = "Default hostname created by API Gateway"
  value       = try(module.api_gateway.gateway_default_hostname, null)
}

output "gateway_resource_id" {
  description = "API Gateway resource id"
  value       = try(module.api_gateway.gateway_id, null)
}

output "cloud_run_service_urls" {
  description = "Cloud Run service URLs by service name"
  value       = { for name, svc in module.cloud_run_services : name => svc.uri }
}

output "runtime_service_account_email" {
  description = "Runtime service account email"
  value       = try(module.iam[0].runtime_service_account_email, null)
}

output "cicd_service_account_email" {
  description = "CI/CD service account email"
  value       = try(module.iam[0].cicd_service_account_email, null)
}

output "pubsub_subscription_name" {
  description = "Primary subscription name"
  value       = try(module.pubsub_retry.subscription_name, null)
}
