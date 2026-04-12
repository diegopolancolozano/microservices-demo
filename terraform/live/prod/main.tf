locals {
  # Load local OpenAPI file only when present; gateway creation is feature-flagged.
  openapi_spec_full_path = "${path.module}/${var.openapi_spec_path}"
  openapi_spec           = fileexists(local.openapi_spec_full_path) ? file(local.openapi_spec_full_path) : ""
}

module "iam" {
  count  = var.enable_iam ? 1 : 0
  source = "../../modules/iam"

  project_id       = var.project_id
  runtime_sa_name  = var.runtime_sa_name
  cicd_sa_name     = var.cicd_sa_name
  runtime_sa_roles = var.runtime_sa_roles
  cicd_sa_roles    = var.cicd_sa_roles
}

module "cloud_run_services" {
  for_each = var.enable_cloud_run ? var.cloud_run_services : {}
  source   = "../../modules/cloud_run_service"

  project_id            = var.project_id
  region                = var.region
  service_name          = each.key
  image                 = each.value.image
  container_port        = each.value.container_port
  allow_unauthenticated = each.value.allow_unauthenticated
  service_account_email = each.value.service_account_email
  env_vars              = each.value.env
  labels                = var.labels
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  enabled       = var.enable_api_gateway
  project_id    = var.project_id
  region        = var.region
  api_id        = var.api_id
  api_config_id = var.api_config_id
  gateway_id    = var.gateway_id
  openapi_spec  = local.openapi_spec
  labels        = var.labels
}

module "pubsub_retry" {
  source = "../../modules/pubsub_retry"

  enabled               = var.enable_pubsub_retry
  project_id            = var.project_id
  topic_name            = var.pubsub_topic_name
  subscription_name     = var.pubsub_subscription_name
  dead_letter_topic     = var.pubsub_dlq_topic_name
  max_delivery_attempts = var.max_delivery_attempts
  min_retry_backoff     = var.min_retry_backoff
  max_retry_backoff     = var.max_retry_backoff
  ack_deadline_seconds  = var.ack_deadline_seconds
  push_endpoint         = var.retry_push_endpoint
  labels                = var.labels
}

module "monitoring" {
  source = "../../modules/monitoring"

  enabled               = var.enable_monitoring
  project_id            = var.project_id
  api_gateway_id        = var.api_id
  subscription_name     = var.pubsub_subscription_name
  notification_channels = var.notification_channels
}
