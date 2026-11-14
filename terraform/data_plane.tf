
# Bigquery Table

resource "google_bigquery_dataset" "sdv_ota_fleet_readiness" {
  dataset_id = "sdv_ota_fleet_readiness"
}

resource "google_bigquery_table" "vehicle_telemetry" {
  dataset_id          = google_bigquery_dataset.sdv_ota_fleet_readiness.dataset_id
  table_id            = "vehicle_telemetry"
  deletion_protection = false
  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }
  schema              = <<EOF
[
  {
    "name": "vehicle_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "VehicleId Id"
  },
  {
    "name": "timestamp",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "Timestamp of the message"
  },
  {
    "name": "battery_soc",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": "battery soc"
  },
  {
    "name": "speed_kph",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": "speed kph"
  },
  {
    "name": "parking_brake_engaged",
    "type": "BOOL",
    "mode": "NULLABLE",
    "description": "parking brake"
  },
  {
    "name": "connectivity_online",
    "type": "BOOL",
    "mode": "NULLABLE",
    "description": "connectivity"
  },
  {
    "name": "signal_strength_dbm",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": "connectivity"
  },
  {
    "name": "software_version",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "software version"
  },
  {
    "name": "ota_update_state",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "ota update state"
  },
  {
    "name": "region",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "region"
  }
]
  EOF
}

resource "google_bigquery_table_iam_member" "push_subscription_by_pubsub_sa" {
  dataset_id = google_bigquery_dataset.sdv_ota_fleet_readiness.dataset_id
  member     = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  role       = "roles/bigquery.dataEditor"
  table_id   = google_bigquery_table.vehicle_telemetry.table_id
}

# Pub sub w/ bigquery subscription
resource "google_pubsub_topic" "vehicle_state_topic" {
  name = "vehicle-state-topic"
}

# NOTES
# Schema evolution considerations
# Casual approach w data governance of vehicle state.
# Cloud side is responsible for the data quality.
resource "google_pubsub_subscription" "vehicle_state_topic_bq_sub" {
  name  = "${google_pubsub_topic.vehicle_state_topic.name}-sub"
  topic = google_pubsub_topic.vehicle_state_topic.id
  bigquery_config {
    table = "${google_bigquery_table.vehicle_telemetry.project}.${google_bigquery_table.vehicle_telemetry.dataset_id}.${google_bigquery_table.vehicle_telemetry.table_id}"
    use_table_schema   = true
  }
}