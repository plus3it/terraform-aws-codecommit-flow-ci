variable "stage" {
  type        = string
  description = "Name of the stage"
}

variable "stage_description" {
  type        = string
  description = "Description of the stage, used in resources created by this module"
}

variable "target_arn" {
  type        = string
  description = "ARN of the resource that the event will trigger"
}

variable "repo_name" {
  type        = string
  description = "Name of the CodeCommit repository"
}

variable "event_pattern" {
  type        = string
  description = "CloudWatch Event pattern that triggers the CodeBuild job"
  default     = ""
}

variable "schedule_expression" {
  type        = string
  description = "CloudWatch Event schedule that triggers the CodeBuild job"
  default     = ""
}
