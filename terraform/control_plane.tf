
resource "google_artifact_registry_repository" "sdv-ota-fleet-readiness" {
  location      = local.region
  repository_id = "sdv-ota-fleet-readiness"
  description   = "App for sdv-ota-fleet-readiness"
  format        = "DOCKER"
}