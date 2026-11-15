terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>7.23"
    }
  }
}

data "google_project" "project" {}

module "data_plane" {
  source = "./data_plane"

  region_name    = "asia-northeast1"
  zone_name      = "asia-northeast1-a"
  vpc_id         = google_compute_network.sdv-ota-fleet-readiness.id
  project_number = data.google_project.project.number
}