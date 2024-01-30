output "name" {
  description = "The trimmed name of the resource"
  value       = "${local.prefix}-${random_string.suffix.result}"
}
