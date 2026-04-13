variable "project_id" {
  description = "GCP project id for prod"
  type        = string
  default     = "CHANGE_ME_PROJECT_ID"
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "us-central1"
}

variable "labels" {
  description = "Common labels applied to resources"
  type        = map(string)
  default = {
    "managed-by" = "terraform"
    "workload"   = "microservices-demo"
    "env"        = "prod"
  }
}

variable "enable_iam" {
  description = "Enable IAM service accounts and project role bindings"
  type        = bool
  default     = false
}

variable "enable_cloud_run" {
  description = "Enable Cloud Run service deployment"
  type        = bool
  default     = false
}

variable "enable_api_gateway" {
  description = "Enable API Gateway resources"
  type        = bool
  default     = false
}

variable "enable_pubsub_retry" {
  description = "Enable Pub/Sub topic/subscription retry and DLQ resources"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable basic monitoring alerts"
  type        = bool
  default     = false
}

variable "runtime_sa_name" {
  description = "Runtime service account name"
  type        = string
  default     = "microservices-runtime"
}

variable "cicd_sa_name" {
  description = "CI/CD deployer service account name"
  type        = string
  default     = "terraform-deployer"
}

variable "runtime_sa_roles" {
  description = "Project roles for runtime service account"
  type        = set(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/pubsub.subscriber"
  ]
}

variable "cicd_sa_roles" {
  description = "Project roles for terraform deployer account"
  type        = set(string)
  default = [
    "roles/apigateway.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/monitoring.editor",
    "roles/pubsub.admin",
    "roles/run.admin",
    "roles/serviceusage.serviceUsageAdmin"
  ]
}

variable "cloud_run_services" {
  description = "Cloud Run services to deploy"
  type = map(object({
    image                 = string
    container_port        = number
    allow_unauthenticated = bool
    service_account_email = string
    env                   = map(string)
  }))
  default = {}
}

variable "api_id" {
  description = "API Gateway API id"
  type        = string
  default     = "microservices-api"
}

variable "api_config_id" {
  description = "API Gateway config id"
  type        = string
  default     = "prod"
}

variable "gateway_id" {
  description = "API Gateway gateway id"
  type        = string
  default     = "microservices-gateway"
}

variable "openapi_spec_path" {
  description = "Path to OpenAPI spec file used by API Gateway"
  type        = string
  default     = "openapi.yaml"
}

variable "pubsub_topic_name" {
  description = "Main topic for async processing"
  type        = string
  default     = "votes"
}

variable "pubsub_subscription_name" {
  description = "Main subscription for worker consumers"
  type        = string
  default     = "votes-worker-sub"
}

variable "pubsub_dlq_topic_name" {
  description = "Dead letter topic name"
  type        = string
  default     = "votes-dlq"
}

variable "max_delivery_attempts" {
  description = "Max delivery attempts before dead-lettering"
  type        = number
  default     = 10
}

variable "min_retry_backoff" {
  description = "Minimum retry backoff duration"
  type        = string
  default     = "10s"
}

variable "max_retry_backoff" {
  description = "Maximum retry backoff duration"
  type        = string
  default     = "120s"
}

variable "ack_deadline_seconds" {
  description = "Ack deadline for subscription"
  type        = number
  default     = 30
}

variable "retry_push_endpoint" {
  description = "Optional push endpoint for subscription (leave empty for pull)"
  type        = string
  default     = ""
}

variable "notification_channels" {
  description = "Monitoring notification channel IDs"
  type        = list(string)
  default     = []
}
