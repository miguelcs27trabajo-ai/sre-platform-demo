output "artifact_registry_url" {
  description = "URL del Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/sre-platform-demo"
}
