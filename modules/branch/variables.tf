variable "branch" {
  type        = string
  description = "Name of the branch where updates will trigger a build"
  default     = "master"
}

variable "repo_name" {
  type        = string
  description = "Name of the CodeCommit repository"
}

variable "buildspec" {
  type        = string
  description = "Buildspec used when the specified branch is updated"
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
