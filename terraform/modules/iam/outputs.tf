output "runtime_service_account_email" {
  description = "Runtime service account email"
  value       = google_service_account.runtime.email
}

output "cicd_service_account_email" {
  description = "CI/CD service account email"
  value       = google_service_account.cicd.email
}
