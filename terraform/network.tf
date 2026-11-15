resource "google_compute_network" "sdv-ota-fleet-readiness" {
  name                    = "sdv-ota-fleet-readiness"
  auto_create_subnetworks = false
}

resource "google_compute_router" "router" {
  name    = "main"
  region  = "asia-northeast1"
  network = google_compute_network.sdv-ota-fleet-readiness.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "main-nat"
  router                             = google_compute_router.router.name
  region                             = "asia-northeast1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name = module.data_plane.subnet.id
    source_ip_ranges_to_nat = ["LIST_OF_SECONDARY_IP_RANGES"]
    secondary_ip_range_names = [
      module.data_plane.subnet.pod_range_name
    ]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}