variable "codecommit_repo_name" {
  type        = "string"
  description = "Name of the CodeCommit repository"
}

variable "release_branch" {
  type        = "string"
  description = "Name of the release branch"
  default     = "master"
}

variable "prior_version_command" {
  type        = "string"
  description = "Command used to identify the prior version"
  default     = "git describe --abbrev=0 --tags"
}

variable "release_version_command" {
  type        = "string"
  description = "Command used to identify the release version"
  default     = "grep '^current_version' $CODEBUILD_SRC_DIR/.bumpversion.cfg | sed 's/^.*= //'"
}
