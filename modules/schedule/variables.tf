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

variable "badge_enabled" {
  type        = bool
  description = "Generates a publicly-accessible URL for the projects build badge"
  default     = null
}

variable "build_timeout" {
  type        = number
  description = "How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed"
  default     = null
}

variable "queued_timeout" {
  type        = number
  description = "How long in minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out"
  default     = null
}
variable "encryption_key" {
  type        = string
  description = "The AWS Key Management Service (AWS KMS) customer master key (CMK) to be used for encrypting the build project's build output artifacts"
  default     = null
}
variable "source_version" {
  type        = string
  description = "A version of the build input to be built for this project. If not specified, the latest version is used"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resource"
  default     = {}
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

variable "python_runtime" {
  type        = string
  description = "Python runtime for the handler Lambda function"
  default     = null
}
