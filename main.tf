terraform {
  required_providers {
    ko = {
      source = "ko-build/ko"
    }
    google = {
      source = "hashicorp/google"
    }
  }
}

resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudscheduler" {
  service = "cloudscheduler.googleapis.com"

  disable_on_destroy = false
}

locals {
  repo = var.repository != "" ? var.repository : "gcr.io/${var.project_id}/${var.name}"
}

resource "ko_build" "image" {
  importpath  = var.importpath
  working_dir = var.working_dir
  base_image  = var.base_image
  repo        = local.repo
}

resource "google_cloud_run_v2_job" "job" {
  name         = "${var.name}-cron"
  location     = var.region
  launch_stage = "BETA"

  template {
    template {
      service_account = var.service_account
      containers {
        image = ko_build.image.image_ref

        dynamic "env" {
          for_each = var.env
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = var.secret_env
          content {
            name = env.key
            value_source {
              secret_key_ref {
                secret  = env.value
                version = "latest"
              }
            }
          }
        }
      }
    }
  }
}

resource "google_cloud_scheduler_job" "cron" {
  name     = "${var.name}-cron"
  schedule = var.schedule
  region   = var.region

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.job.name}:run"

    oauth_token {
      service_account_email = var.service_account
    }
  }
  depends_on = [google_project_iam_member.cron_secretmanager_access]
}

resource "google_project_iam_member" "cron_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${var.service_account}"
}

resource "google_project_iam_member" "cron_secretmanager_access" {
  count = var.secret_env != {} ? 1 : 0

  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${var.service_account}"
}
