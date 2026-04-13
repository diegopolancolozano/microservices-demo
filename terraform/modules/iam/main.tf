resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = var.runtime_sa_name
  display_name = "Microservices runtime SA"
}

resource "google_service_account" "cicd" {
  project      = var.project_id
  account_id   = var.cicd_sa_name
  display_name = "Terraform deployer SA"
}

resource "google_project_iam_member" "runtime_roles" {
  for_each = var.runtime_sa_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_project_iam_member" "cicd_roles" {
  for_each = var.cicd_sa_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cicd.email}"
}
