provider "google" {
  project = var.project_id
}

variable "project_id" {
  type        = string
  description = "The project that will host the prober."
}

# NB: Prefer a Service Account with fewer permissions.
data "google_compute_default_service_account" "default" {
}

module "cron" {
  source = "../"

  project_id            = var.project_id
  name                  = "example"
  service_account = data.google_compute_default_service_account.default.email

  importpath  = "github.com/chainguard-dev/terraform-google-cron/example"
  working_dir = path.module

  schedule = "*/8 * * * *"

  env = {
    EXAMPLE_ENV = "honk"
  }
}
