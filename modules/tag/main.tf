terraform {
  required_version = ">= 0.12"
}

locals {
  stage             = "tag"
  stage_description = "Execute a job/buildspec when a tag is created in ${var.repo_name}"

  event_pattern = <<-PATTERN
    {
      "detail-type": ["CodeCommit Repository State Change"],
      "source": ["aws.codecommit"],
      "detail": {
        "event": [
            "referenceCreated",
            "referenceUpdated"
        ],
        "repositoryName": ["${var.repo_name}"],
        "referenceType": ["tag"]
      }
    }
    PATTERN
}

module "handler" {
  source = "../_internal/handler"

  handler           = "tag_handler"
  stage             = local.stage
  stage_description = local.stage_description
  repo_name         = var.repo_name
  project_arn       = module.runner.codebuild_project_arn
}

module "runner" {
  source = "../_internal/runner"

  stage                 = local.stage
  stage_description     = local.stage_description
  repo_name             = var.repo_name
  buildspec             = var.buildspec
  artifacts             = var.artifacts
  environment           = var.environment
  environment_variables = var.environment_variables
  policy_override       = var.policy_override
  policy_arns           = var.policy_arns
}

module "trigger" {
  source = "../_internal/trigger"

  stage             = local.stage
  stage_description = local.stage_description
  target_arn        = module.handler.function_arn
  repo_name         = var.repo_name
  event_pattern     = local.event_pattern
}

resource "aws_lambda_permission" "trigger" {
  action        = "lambda:InvokeFunction"
  function_name = module.handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.trigger.events_rule_arn
}
