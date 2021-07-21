output "branch" {
  description = "Outputs from the branch module"
  value       = var.event == "branch" ? module.branch[0] : null
}

output "review" {
  description = "Outputs from the review module"
  value       = var.event == "review" ? module.review[0] : null
}

output "schedule" {
  description = "Outputs from the schedule module"
  value       = var.event == "schedule" ? module.schedule[0] : null
}

output "tag" {
  description = "Outputs from the tag module"
  value       = var.event == "tag" ? module.tag[0] : null
}
