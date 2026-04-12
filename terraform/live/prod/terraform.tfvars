project_id = "my-prod-project"
region     = "us-central1"

enable_iam          = true
enable_cloud_run    = true
enable_api_gateway  = true
enable_pubsub_retry = true
enable_monitoring   = true

runtime_sa_name = "microservices-runtime"
cicd_sa_name    = "terraform-deployer"

api_id        = "microservices-api"
api_config_id = "prod-v1"
gateway_id    = "microservices-gateway"

pubsub_topic_name        = "votes"
pubsub_subscription_name = "votes-worker-sub"
pubsub_dlq_topic_name    = "votes-dlq"
max_delivery_attempts    = 10
min_retry_backoff        = "10s"
max_retry_backoff        = "120s"
ack_deadline_seconds     = 30

# Leave empty for pull subscriptions. Set endpoint for push delivery mode.
retry_push_endpoint = ""

# Fill with real Monitoring channel ids once created in GCP.
notification_channels = []

cloud_run_services = {
  vote = {
    image                 = "us-docker.pkg.dev/my-prod-project/apps/vote:latest"
    container_port        = 8080
    allow_unauthenticated = true
    service_account_email = "microservices-runtime@my-prod-project.iam.gserviceaccount.com"
    env = {
      KAFKA_BROKER = "REPLACE_ME_KAFKA_BROKER"
    }
  }

  result = {
    image                 = "us-docker.pkg.dev/my-prod-project/apps/result:latest"
    container_port        = 80
    allow_unauthenticated = true
    service_account_email = "microservices-runtime@my-prod-project.iam.gserviceaccount.com"
    env = {
      PORT = "80"
    }
  }

  worker = {
    image                 = "us-docker.pkg.dev/my-prod-project/apps/worker:latest"
    container_port        = 8080
    allow_unauthenticated = false
    service_account_email = "microservices-runtime@my-prod-project.iam.gserviceaccount.com"
    env = {
      DATABASE_URL = "REPLACE_ME_DATABASE_URL"
      KAFKA_BROKER = "REPLACE_ME_KAFKA_BROKER"
    }
  }
}
