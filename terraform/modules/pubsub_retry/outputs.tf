output "topic_id" {
  description = "Main topic id"
  value       = try(google_pubsub_topic.main[0].id, null)
}

output "dead_letter_topic_id" {
  description = "Dead letter topic id"
  value       = try(google_pubsub_topic.dlq[0].id, null)
}

output "subscription_name" {
  description = "Main subscription name"
  value       = try(google_pubsub_subscription.main[0].name, null)
}
