module "branch" {
  source = "./modules/branch"
  count  = var.event == "branch" ? 1 : 0

  branch      = var.branch
  name_prefix = var.name_prefix
  repo_name   = var.repo_name

  artifacts             = var.artifacts
  buildspec             = var.buildspec
  badge_enabled         = var.badge_enabled
  build_timeout         = var.build_timeout
  encryption_key        = var.encryption_key
  environment           = var.environment
  environment_variables = var.environment_variables
  policy_arns           = var.policy_arns
  policy_override       = var.policy_override
  python_runtime        = var.python_runtime
  queued_timeout        = var.queued_timeout
  source_version        = var.source_version
  tags                  = var.tags
}

module "review" {
  source = "./modules/review"
  count  = var.event == "review" ? 1 : 0

  name_prefix = var.name_prefix
  repo_name   = var.repo_name

  artifacts             = var.artifacts
  buildspec             = var.buildspec
  badge_enabled         = var.badge_enabled
  build_timeout         = var.build_timeout
  encryption_key        = var.encryption_key
  environment           = var.environment
  environment_variables = var.environment_variables
  policy_arns           = var.policy_arns
  policy_override       = var.policy_override
  python_runtime        = var.python_runtime
  queued_timeout        = var.queued_timeout
  source_version        = var.source_version
  tags                  = var.tags
}

module "schedule" {
  source = "./modules/schedule"
  count  = var.event == "schedule" ? 1 : 0

  name_prefix         = var.name_prefix
  repo_name           = var.repo_name
  schedule_expression = var.schedule_expression

  artifacts             = var.artifacts
  buildspec             = var.buildspec
  badge_enabled         = var.badge_enabled
  build_timeout         = var.build_timeout
  encryption_key        = var.encryption_key
  environment           = var.environment
  environment_variables = var.environment_variables
  policy_arns           = var.policy_arns
  policy_override       = var.policy_override
  python_runtime        = var.python_runtime
  queued_timeout        = var.queued_timeout
  source_version        = var.source_version
  tags                  = var.tags
}

module "tag" {
  source = "./modules/tag"
  count  = var.event == "tag" ? 1 : 0

  name_prefix = var.name_prefix
  repo_name   = var.repo_name

  artifacts             = var.artifacts
  buildspec             = var.buildspec
  badge_enabled         = var.badge_enabled
  build_timeout         = var.build_timeout
  encryption_key        = var.encryption_key
  environment           = var.environment
  environment_variables = var.environment_variables
  policy_arns           = var.policy_arns
  policy_override       = var.policy_override
  python_runtime        = var.python_runtime
  queued_timeout        = var.queued_timeout
  source_version        = var.source_version
  tags                  = var.tags
}
