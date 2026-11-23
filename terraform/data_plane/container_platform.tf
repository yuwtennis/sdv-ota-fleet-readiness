
# Zonal cluster
resource "google_container_cluster" "data_pipeline" {
  name = "data-plane-cluster"

  network    = var.vpc_id
  subnetwork = google_compute_subnetwork.data_plane.id
  location   = var.zone_name

  ip_allocation_policy {
    stack_type                    = "IPV4"
    services_secondary_range_name = google_compute_subnetwork.data_plane.secondary_ip_range[0].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.data_plane.secondary_ip_range[1].range_name
  }

  deletion_protection = false
  workload_identity_config {
    workload_pool = "${var.project.id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "data-plane-cluster"
  cluster    = google_container_cluster.data_pipeline.id
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-standard-2"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.data_broker_pubsub_write.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}