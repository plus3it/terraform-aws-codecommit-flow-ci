output "codebuild_project_arn" {
  description = "ARN of the CodeBuild Project"
  value       = "${aws_codebuild_project.this.id}"
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild Project"
  value       = "${aws_codebuild_project.this.name}"
}

output "codebuild_project_service_role" {
  description = "ARN of the CodeBuild Project Service Role"
  value       = "${aws_codebuild_project.this.service_role}"
}
