terraform {
  # GCS backend is configured at runtime from CI/CD using:
  # -backend-config="bucket=..." -backend-config="prefix=..."
  backend "gcs" {}
}
