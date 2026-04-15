variable "enabled" {
  description = "Enable monitoring alerts"
  type        = bool
  default     = false
}

variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "api_gateway_id" {
  description = "API id used in API Gateway metrics"
  type        = string
  default     = ""
}

variable "subscription_name" {
  description = "Pub/Sub subscription name for backlog monitoring"
  type        = string
  default     = ""
}

variable "notification_channels" {
  description = "Notification channel ids"
  type        = list(string)
  default     = []
}
