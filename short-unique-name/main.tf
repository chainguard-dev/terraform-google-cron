locals {
  suffix = substr(sha256(var.name), -4, -1)
  prefix = substr(var.name, 0, var.max_length - 5)
  short_name = "${local.prefix}-${local.suffix}"
}
