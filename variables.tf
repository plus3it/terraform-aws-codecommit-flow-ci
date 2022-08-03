variable "event" {
  type        = string
  description = "Type of event that will trigger the flow-ci job"

  validation {
    condition = contains(
      [
        "branch",
        "review",
        "schedule",
        "tag",
      ],
      var.event
    )

    error_message = "The event must be one of: branch, review, schedule, or tag."
  }
}

variable "repo_name" {
  type        = string
  description = "Name of the CodeCommit repository"
}

variable "artifacts" {
  type        = map(string)
  description = "Map defining an artifacts object for the CodeBuild job"
  default     = {}
}

variable "badge_enabled" {
  type        = bool
  description = "Generates a publicly-accessible URL for the projects build badge"
  default     = null
}

variable "branch" {
  type        = string
  description = "Name of the branch where updates will trigger a build. Used only when `event` is \"branch\""
  default     = null
}

variable "build_timeout" {
  type        = number
  description = "How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed"
  default     = null
}

variable "buildspec" {
  type        = string
  description = "Buildspec used when the specified branch is updated"
  default     = ""
}

variable "encryption_key" {
  type        = string
  description = "The AWS Key Management Service (AWS KMS) customer master key (CMK) to be used for encrypting the build project's build output artifacts"
  default     = null
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

variable "queued_timeout" {
  type        = number
  description = "How long in minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out"
  default     = null
}

variable "schedule_expression" {
  type        = string
  description = "CloudWatch Event schedule that triggers the CodeBuild job. Required when `event` is \"schedule\""
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
