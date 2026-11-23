
resource "google_service_account" "data_broker_pubsub_write" {
  account_id   = "data-broker-pubsub-write"
  display_name = "Data broker pubsub write"
}

resource "google_project_iam_member" "allow_data_broker_pubsub_write" {
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.data_broker_pubsub_write.email}"
  project = var.project.id
}

// For DNS challenge w/ Lets encrypt
resource "google_service_account" "dns01_solver" {
  account_id = "dns01-solver"
  display_name = "DNS01 solver"
}

resource "google_service_account_iam_member" "allow_wi_to_certmanager" {
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project.id}.svc.id.goog[cert-manager/cert-manager]"
  service_account_id = google_service_account.dns01_solver.id
}

resource "google_project_iam_member" "allow_dns_editor_to_dns01_solver" {
  role               = "roles/dns.editor"
  member             = "serviceAccount:${google_service_account.dns01_solver.email}"
  project            = var.project.id
}