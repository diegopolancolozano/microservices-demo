variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "runtime_sa_name" {
  description = "Runtime service account id"
  type        = string
}

variable "cicd_sa_name" {
  description = "CI/CD service account id"
  type        = string
}

variable "runtime_sa_roles" {
  description = "Roles for runtime service account"
  type        = set(string)
  default     = []
}

variable "cicd_sa_roles" {
  description = "Roles for CI/CD service account"
  type        = set(string)
  default     = []
}
