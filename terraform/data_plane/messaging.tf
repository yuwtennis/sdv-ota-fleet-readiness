
# Bigquery Table

resource "google_bigquery_dataset" "sdv_ota_fleet_readiness" {
  dataset_id = "sdv_ota_fleet_readiness"
  location   = var.region_name
}

resource "google_bigquery_table" "vehicle_telemetry" {
  dataset_id          = google_bigquery_dataset.sdv_ota_fleet_readiness.dataset_id
  table_id            = "raw_vehicle_telemetry"
  deletion_protection = false
  schema = <<EOF
[
  {
    "name": "publish_received_at",
    "type": "INT64",
    "mode": "NULLABLE",
    "description": "Publish received time"
  },
  {
    "name": "timestamp",
    "type": "INT64",
    "mode": "NULLABLE",
    "description": "Event generated time"
  },
  {
    "name": "clientid",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Client Id"
  },
  {
    "name": "payload",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Payload"
  }
]
  EOF
}

resource "google_bigquery_table_iam_member" "push_subscription_by_pubsub_sa" {
  dataset_id = google_bigquery_dataset.sdv_ota_fleet_readiness.dataset_id
  member     = "serviceAccount:service-${var.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  role       = "roles/bigquery.dataEditor"
  table_id   = google_bigquery_table.vehicle_telemetry.table_id
  depends_on = [
    google_bigquery_table.vehicle_telemetry
  ]
}

# Pub sub w/ bigquery subscription
resource "google_pubsub_topic" "vehicle_state_topic" {
  name = "vehicle-state-topic"
}

# DLQ
resource "google_pubsub_topic" "vehicle_state_topic_dlq" {
  name = "vehicle-state-topic-dlq"
}

# NOTES
# Schema evolution considerations
# Casual approach w data governance of vehicle state.
# Cloud side is responsible for the data quality.
resource "google_pubsub_subscription" "vehicle_state_topic_bq_sub" {
  name  = "${google_pubsub_topic.vehicle_state_topic.name}-sub"
  topic = google_pubsub_topic.vehicle_state_topic.id
  bigquery_config {
    table            = "${google_bigquery_table.vehicle_telemetry.project}.${google_bigquery_table.vehicle_telemetry.dataset_id}.${google_bigquery_table.vehicle_telemetry.table_id}"
    use_table_schema = true
    drop_unknown_fields = true
  }

  dead_letter_policy {
    dead_letter_topic = google_pubsub_topic.vehicle_state_topic_dlq.id
    max_delivery_attempts = 5
  }
}

