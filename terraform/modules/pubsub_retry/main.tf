resource "google_pubsub_topic" "main" {
  count   = var.enabled ? 1 : 0
  project = var.project_id
  name    = var.topic_name
  labels  = var.labels
}

resource "google_pubsub_topic" "dlq" {
  count   = var.enabled ? 1 : 0
  project = var.project_id
  name    = var.dead_letter_topic
  labels  = var.labels
}

resource "google_pubsub_subscription" "main" {
  count   = var.enabled ? 1 : 0
  project = var.project_id
  name    = var.subscription_name
  topic   = google_pubsub_topic.main[0].id
  labels  = var.labels

  ack_deadline_seconds = var.ack_deadline_seconds

  retry_policy {
    minimum_backoff = var.min_retry_backoff
    maximum_backoff = var.max_retry_backoff
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq[0].id
    max_delivery_attempts = var.max_delivery_attempts
  }

  dynamic "push_config" {
    for_each = var.push_endpoint == "" ? [] : [1]
    content {
      push_endpoint = var.push_endpoint
    }
  }
}
