resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  prefix     = substr(var.name, 0, var.max_length - 5)
  short_name = "${local.prefix}-${random_string.suffix.result}"
}
