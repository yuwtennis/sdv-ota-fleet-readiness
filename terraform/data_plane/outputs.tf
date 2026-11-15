
output "subnet" {
  value = {
    id = google_compute_subnetwork.data_plane.id
    pod_range_name = google_compute_subnetwork.data_plane.secondary_ip_range[0].range_name
  }
}
