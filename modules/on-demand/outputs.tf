output "codebuild_project_arn" {
  description = "ARN of the CodeBuild Project"
  value       = module.runner.codebuild_project_arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild Project"
  value       = module.runner.codebuild_project_name
}

output "codebuild_project_service_role" {
  description = "ARN of the CodeBuild Project Service Role"
  value       = module.runner.codebuild_project_service_role
}
