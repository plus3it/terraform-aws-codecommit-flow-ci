terraform {
  required_version = ">= 0.12"
}

locals {
  stage             = "on-demand"
  stage_description = "Execute a job/buildspec on demand"
}

module "runner" {
  source = "../_internal/runner"

  name_prefix           = var.name_prefix
  repo_name             = var.repo_name
  stage                 = local.stage
  stage_description     = local.stage_description
  buildspec             = var.buildspec
  artifacts             = var.artifacts
  environment           = var.environment
  environment_variables = var.environment_variables
  policy_override       = var.policy_override
  policy_arns           = var.policy_arns
  vpc_config            = var.vpc_config

  badge_enabled  = var.badge_enabled
  build_timeout  = var.build_timeout
  queued_timeout = var.queued_timeout
  encryption_key = var.encryption_key
  source_version = var.source_version
  tags           = var.tags
}
