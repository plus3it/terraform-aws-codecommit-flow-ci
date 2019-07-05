variable "repo_name" {
  type        = string
  description = "Name of the CodeCommit repository"
}

variable "schedule_expression" {
  type        = string
  description = "CloudWatch Event schedule that triggers the CodeBuild job"
}

variable "buildspec" {
  type        = string
  description = "Buildspec used when a tag reference is created or updated"
  default     = ""
}

variable "artifacts" {
  type        = map(string)
  description = "Map defining an artifacts object for the CodeBuild job"
  default     = {}
}

variable "environment" {
  type        = map(string)
  description = "Map describing the environment object for the CodeBuild job"
  default     = {}
}

variable "environment_variables" {
  type        = list(map(string))
  description = "List of environment variable map objects for the CodeBuild job"
  default     = []
}

variable "policy_arns" {
  type        = list(string)
  description = "List of IAM policy ARNs to attach to the CodeBuild service role"
  default     = []
}

variable "policy_override" {
  type        = string
  description = "IAM policy document in JSON that extends the basic inline CodeBuild service role"
  default     = ""
}
