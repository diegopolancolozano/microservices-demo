project_id = "microservices-taller-2026"
region     = "us-central1"

enable_iam          = true
enable_cloud_run    = true
enable_api_gateway  = true
enable_pubsub_retry = false
enable_monitoring   = false

runtime_sa_name = "microservices-runtime"
cicd_sa_name    = "terraform-deployer"

api_id        = "microservices-api"
api_config_id = "prod-v1"
gateway_id    = "microservices-gateway"

rate_limit_per_minute = 5
circuit_breaker_timeout_seconds = 2

pubsub_topic_name        = "votes"
pubsub_subscription_name = "votes-worker-sub"
pubsub_dlq_topic_name    = "votes-dlq"
max_delivery_attempts    = 10
min_retry_backoff        = "10s"
max_retry_backoff        = "120s"
ack_deadline_seconds     = 30

retry_push_endpoint = ""
notification_channels = []

cloud_run_services = {
  vote = {
    image                 = "gcr.io/cloudrun/hello"
    container_port        = 8080
    allow_unauthenticated = true
    service_account_email = "microservices-runtime@microservices-taller-2026.iam.gserviceaccount.com"
    env = {}
  }

  result = {
    image                 = "gcr.io/cloudrun/hello"
    container_port        = 80
    allow_unauthenticated = true
    service_account_email = "microservices-runtime@microservices-taller-2026.iam.gserviceaccount.com"
    env = {}
  }

  worker = {
    image                 = "gcr.io/cloudrun/hello"
    container_port        = 8080
    allow_unauthenticated = false
    service_account_email = "microservices-runtime@microservices-taller-2026.iam.gserviceaccount.com"
    env = {}
  }
}