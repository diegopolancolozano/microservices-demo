project_id = "microservices-taller-2026"
region     = "us-central1"

enable_iam          = true
enable_cloud_run    = true
enable_api_gateway  = false
enable_pubsub_retry = false
enable_monitoring   = false

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

retry_push_endpoint   = ""
notification_channels = []

cloud_run_services = {
  vote = {
    image                 = "gcr.io/microservices-taller-2026/vote:latest"
    container_port        = 8080
    allow_unauthenticated = true
    service_account_email = "microservices-runtime@microservices-taller-2026.iam.gserviceaccount.com"
    env = {
      # Forzar redeploy (cambiar este valor en cada despliegue)
      UPDATE_TIMESTAMP = "2026-04-15-50"

      # Kafka para vote
      KAFKA_BROKER     = "pkc-619z3.us-east1.gcp.confluent.cloud:9092"
      KAFKA_API_KEY    = "U4NGS6RXSS6MHBZW"
      KAFKA_API_SECRET = "cfltETmfvCjbrYIx495radD6UwYr+tGlih08sRa+3SOTd9ks8gM2fhZA642QPvAA"
      KAFKA_TOPIC      = "topic_0"
    }
    demo-date = "2026-04-15"
  }

  result = {
    image                 = "gcr.io/microservices-taller-2026/result:latest"
    container_port        = 80
    allow_unauthenticated = true
    service_account_email = "microservices-runtime@microservices-taller-2026.iam.gserviceaccount.com"
    env = {
      DATABASE_HOST     = "35.193.85.226"
      DATABASE_PORT     = "5432"
      DATABASE_USER     = "okteto"
      DATABASE_PASSWORD = "okteto"
      DATABASE_NAME     = "votes"
    }
  }

  worker = {
    image                 = "gcr.io/microservices-taller-2026/worker:latest"
    container_port        = 8080
    allow_unauthenticated = false
    service_account_email = "microservices-runtime@microservices-taller-2026.iam.gserviceaccount.com"
    env = {
      # PostgreSQL
      DATABASE_HOST     = "35.193.85.226"
      DATABASE_PORT     = "5432"
      DATABASE_USER     = "okteto"
      DATABASE_PASSWORD = "okteto"
      DATABASE_NAME     = "votes"

      # Kafka
      KAFKA_BROKER     = "pkc-619z3.us-east1.gcp.confluent.cloud:9092"
      KAFKA_TOPIC      = "topic_0"
      KAFKA_API_KEY    = "U4NGS6RXSS6MHBZW"
      KAFKA_API_SECRET = "cfltETmfvCjbrYIx495radD6UwYr+tGlih08sRa+3SOTd9ks8gM2fhZA642QPvAA"
    }
  }
}
