output "id" {
  description = "Cloud Run service id"
  value       = google_cloud_run_v2_service.this.id
}

output "uri" {
  description = "Cloud Run public URL"
  value       = google_cloud_run_v2_service.this.uri
}
