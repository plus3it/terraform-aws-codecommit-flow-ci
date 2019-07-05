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

variable "buildspec" {
  type        = string
  description = "Buildspec used when the release branch is updated"
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
  description = "List of IAM policiy ARNs to attach to the CodeBuild service role"
}

variable "policy_override" {
  type        = string
  description = "IAM policy document in JSON that extends the basic inline CodeBuild service role"
}
