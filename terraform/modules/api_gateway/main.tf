resource "google_api_gateway_api" "this" {
  count    = var.enabled ? 1 : 0
  provider = google-beta
  project  = var.project_id

  api_id       = var.api_id
  display_name = var.api_id
  labels       = var.labels
}

resource "google_api_gateway_api_config" "this" {
  count    = var.enabled ? 1 : 0
  provider = google-beta
  project  = var.project_id

  api           = google_api_gateway_api.this[0].api_id
  api_config_id = var.api_config_id
  display_name  = var.api_config_id

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = base64encode(var.openapi_spec)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "this" {
  count    = var.enabled ? 1 : 0
  provider = google-beta
  project  = var.project_id

  region       = var.region
  gateway_id   = var.gateway_id
  api_config   = google_api_gateway_api_config.this[0].id
  display_name = var.gateway_id
  labels       = var.labels
}
