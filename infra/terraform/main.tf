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

# Service Account que usará GitLab para autenticarse
resource "google_service_account" "gitlab_ci" {
  account_id   = "gitlab-ci"
  display_name = "GitLab CI Service Account"
  description  = "Used by GitLab CI to push images and deploy to Cloud Run"
}

# Permisos de la Service Account
# Puede subir imágenes a Artifact Registry
resource "google_project_iam_member" "gitlab_ci_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.gitlab_ci.email}"
}

# Puede desplegar en Cloud Run
resource "google_project_iam_member" "gitlab_ci_cloud_run" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.gitlab_ci.email}"
}

# Workload Identity Pool: el "puente" entre GitLab y GCP
resource "google_iam_workload_identity_pool" "gitlab" {
  workload_identity_pool_id = "gitlab-pool"
  display_name              = "GitLab Pool"
  description               = "Pool for GitLab CI pipelines"
}

# Workload Identity Provider: configura GitLab como fuente de confianza
resource "google_iam_workload_identity_pool_provider" "gitlab" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.gitlab.workload_identity_pool_id
  workload_identity_pool_provider_id = "gitlab-provider"
  display_name                       = "GitLab Provider"

  oidc {
    issuer_uri = "https://gitlab.com"
  }

  # Solo acepta tokens de tu namespace/usuario de GitLab
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.namespace"  = "assertion.namespace_path"
    "attribute.ref"        = "assertion.ref"
    "attribute.pipeline"   = "assertion.pipeline_id"
  }

  attribute_condition = "assertion.namespace_path.startsWith(\"miguelcs27trabajo-group\")"
}

# Permite que GitLab use la Service Account via WIF
resource "google_service_account_iam_member" "gitlab_wif" {
  service_account_id = google_service_account.gitlab_ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gitlab.name}/attribute.namespace/miguelcs27trabajo-group"
}

# Permite a gitlab-ci actuar como la compute service account
# necesario para desplegar en Cloud Run
resource "google_service_account_iam_member" "gitlab_ci_act_as_compute" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.gitlab_ci.email}"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_cloud_run_v2_service" "dev" {
  name     = "sre-platform-demo-dev"
  location = var.region
  project  = var.project_id

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/sre-platform-demo/api:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    timeout = "30s"
  }

  ingress = "INGRESS_TRAFFIC_ALL"
}

resource "google_cloud_run_v2_service_iam_member" "dev_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.dev.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_container_analysis_note" "cosign" {
  project = var.project_id
  name    = "cosign-attestor-note"

  attestation_authority {
    hint {
      human_readable_name = "Cosign attestor"
    }
  }
}

resource "google_binary_authorization_attestor" "cosign" {
  project = var.project_id
  name    = "cosign-attestor"

  attestation_authority_note {
    note_reference = google_container_analysis_note.cosign.name
  }
}

resource "google_binary_authorization_policy" "policy" {
  project = var.project_id

  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"

    require_attestations_by = [
      google_binary_authorization_attestor.cosign.name
    ]
  }

  global_policy_evaluation_mode = "ENABLE"
}
