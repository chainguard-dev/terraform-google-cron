output "name" {
  description = "The trimmed name of the resource"
  value       = length(var.name) < var.max_length ? var.name : local.short_name
}
