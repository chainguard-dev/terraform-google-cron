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

locals {
  repo = var.repository != "" ? var.repository : "gcr.io/${var.project_id}/${var.name}"
}

resource "ko_build" "image" {
  importpath  = var.importpath
  working_dir = var.working_dir
  base_image  = var.base_image
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
}
