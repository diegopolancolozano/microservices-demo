variable "enabled" {
  description = "Enable Pub/Sub retry and DLQ resources"
  type        = bool
  default     = false
}

variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "topic_name" {
  description = "Main topic name"
  type        = string
}

variable "subscription_name" {
  description = "Main subscription name"
  type        = string
}

variable "dead_letter_topic" {
  description = "Dead letter topic name"
  type        = string
}

variable "max_delivery_attempts" {
  description = "Max attempts before DLQ"
  type        = number
  default     = 10
}

variable "min_retry_backoff" {
  description = "Minimum retry backoff"
  type        = string
  default     = "10s"
}

variable "max_retry_backoff" {
  description = "Maximum retry backoff"
  type        = string
  default     = "120s"
}

variable "ack_deadline_seconds" {
  description = "Ack deadline seconds"
  type        = number
  default     = 30
}

variable "push_endpoint" {
  description = "Optional push endpoint for push subscriptions"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}
