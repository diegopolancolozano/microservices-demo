variable "enabled" {
  description = "Enable API Gateway creation"
  type        = bool
  default     = false
}

variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "Gateway region"
  type        = string
}

variable "api_id" {
  description = "API id"
  type        = string
}

variable "api_config_id" {
  description = "API config id"
  type        = string
}

variable "gateway_id" {
  description = "Gateway id"
  type        = string
}

variable "openapi_spec" {
  description = "OpenAPI spec content"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}
