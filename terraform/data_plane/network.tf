
resource "google_compute_subnetwork" "data_plane" {
  name                     = "data-plane"
  network                  = var.vpc_id
  region                   = var.region_name
  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"

  # Node address range
  ip_cidr_range = "10.0.0.0/24"

  # Pod address range
  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = "192.168.0.0/24"
  }

  # Service address range
  secondary_ip_range {
    range_name    = "services-ranges"
    ip_cidr_range = "192.168.1.0/24"
  }
}