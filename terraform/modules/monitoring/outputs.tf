output "alert_policy_ids" {
  description = "Created alert policy ids"
  value = compact([
    try(google_monitoring_alert_policy.api_gateway_5xx[0].id, null),
    try(google_monitoring_alert_policy.pubsub_backlog[0].id, null)
  ])
}
