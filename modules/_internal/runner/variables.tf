variable "stage" {
  type        = string
  description = "Name of the stage"
}

variable "stage_description" {
  type        = string
  description = "Description of the stage, used in resources created by this module"
}

variable "repo_name" {
  type        = string
  description = "Name of the CodeCommit repository"
}

variable "name_prefix" {
  type        = string
  description = "Prefix to attach to repo name"
  default     = ""
  nullable    = false
}

variable "buildspec" {
  type        = string
  description = "Buildspec used when the release branch is updated"
  default     = null
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
}

variable "environment" {
  type        = map(string)
  description = "Map describing the environment object for the CodeBuild job"
}

variable "environment_variables" {
  type        = list(map(string))
  description = "List of environment variable map objects for the CodeBuild job"
}

variable "policy_arns" {
  type        = list(string)
  description = "List of IAM policy ARNs to attach to the CodeBuild service role"
}

variable "policy_override" {
  type        = string
  description = "IAM policy document in JSON that extends the basic inline CodeBuild service role"
}
