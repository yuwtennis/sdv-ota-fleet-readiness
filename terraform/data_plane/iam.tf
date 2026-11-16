resource "google_service_account" "data_broker_pubsub_write" {
  account_id   = "data-broker-pubsub-write"
  display_name = "Service Account"
}

resource "google_project_iam_member" "data_broker_pubsub_write" {
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.data_broker_pubsub_write.email}"
  project = var.project.id
}