terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Artifact Registry: donde vivirán las imágenes Docker
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "sre-platform-demo"
  format        = "DOCKER"
  description   = "Docker images for SRE Platform Demo"
}
