variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "Cloud Run region"
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "image" {
  description = "Container image"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "allow_unauthenticated" {
  description = "Whether to grant allUsers run.invoker"
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Runtime service account email"
  type        = string
}

variable "env_vars" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}
