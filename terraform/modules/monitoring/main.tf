resource "google_monitoring_alert_policy" "api_gateway_5xx" {
  count   = var.enabled && var.api_gateway_id != "" ? 1 : 0
  project = var.project_id

  display_name = "API Gateway high 5xx"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "5xx requests higher than threshold"
    condition_threshold {
      filter = "metric.type=\"apigateway.googleapis.com/proxy/request_count\" AND resource.type=\"api\" AND metric.label.\"api\"=\"${var.api_gateway_id}\" AND metric.label.\"response_code_class\"=\"5xx\""

      comparison      = "COMPARISON_GT"
      threshold_value = 10
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = "API Gateway is returning too many 5xx responses."
  }
}

resource "google_monitoring_alert_policy" "pubsub_backlog" {
  count   = var.enabled && var.subscription_name != "" ? 1 : 0
  project = var.project_id

  display_name = "PubSub backlog high"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Subscription undelivered messages high"
    condition_threshold {
      filter = "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.type=\"pubsub_subscription\" AND resource.label.\"subscription_id\"=\"${var.subscription_name}\""

      comparison      = "COMPARISON_GT"
      threshold_value = 100
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = "Pub/Sub subscription backlog is growing. Review consumer health and retry behavior."
  }
}
