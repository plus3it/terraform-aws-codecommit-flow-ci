output "codebuild_project_arn" {
  description = "ARN of the CodeBuild Project"
  value       = "${module.runner.codebuild_project_arn}"
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild Project"
  value       = "${module.runner.codebuild_project_name}"
}

output "codebuild_project_service_role" {
  description = "ARN of the CodeBuild Project Service Role"
  value       = "${module.runner.codebuild_project_service_role}"
}

output "events_rule_codebuild_arn" {
  description = "ARN of the CloudWatch Event Rule for CodeBuild"
  value       = "${module.trigger_codebuild.events_rule_arn}"
}

output "events_rule_pull_request_rule_arn" {
  description = "ARN of the CloudWatch Event Rule for Pull Requests"
  value       = "${module.trigger_pull_request.events_rule_arn}"
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = "${module.handler.function_arn}"
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = "${module.handler.function_name}"
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM Role"
  value       = "${module.handler.role_arn}"
}

output "lambda_role_name" {
  description = "Name of the Lambda IAM Role"
  value       = "${module.handler.function_arn}"
}
