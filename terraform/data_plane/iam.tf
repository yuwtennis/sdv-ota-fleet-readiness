resource "google_service_account" "data_broker_pubsub_write" {
  account_id   = "data-broker-pubsub-write"
  display_name = "Service Account"
}