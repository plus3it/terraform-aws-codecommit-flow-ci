output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = "${module.handler.function_arn}"
}

output "function_name" {
  description = "The name of the Lambda function"
  value       = "${module.handler.function_name}"
}

output "role_arn" {
  description = "The ARN of the IAM role created for the Lambda function"
  value       = "${module.handler.role_arn}"
}

output "role_name" {
  description = "The name of the IAM role created for the Lambda function"
  value       = "${module.handler.role_name}"
}
