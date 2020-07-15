terraform {
  required_version = ">= 0.12"
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  stage             = "review"
  stage_description = "Execute a job/buildspec when a pull request is created or updated in ${var.repo_name}"

  repo_arn                 = "arn:${data.aws_partition.current.partition}:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.repo_name}"
  codebuild_log_stream_arn = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.repo_name}-review-flow-ci:log-stream:*"
}

locals {
  event_pattern_pull_request = <<-PATTERN
    {
      "detail-type": ["CodeCommit Pull Request State Change"],
      "source": ["aws.codecommit"],
      "resources": ["${local.repo_arn}"],
      "detail": {
        "event": [
          "pullRequestCreated",
          "pullRequestSourceBranchUpdated"
        ],
        "pullRequestStatus": ["Open"],
        "isMerged": ["False"]
      }
    }
    PATTERN
}

locals {
  event_pattern_codebuild = <<-PATTERN
    {
      "detail-type": ["CodeBuild Build State Change"],
      "source": ["aws.codebuild"],
      "detail": {
        "project-name": ["${module.runner.codebuild_project_name}"]
      }
    }
    PATTERN
}

module "handler" {
  source = "../_internal/handler"

  handler                = "review_handler"
  stage                  = local.stage
  stage_description      = local.stage_description
  repo_name              = var.repo_name
  project_arn            = module.runner.codebuild_project_arn
  lambda_policy_override = data.aws_iam_policy_document.handler.json
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

  badge_enabled  = var.badge_enabled
  build_timeout  = var.build_timeout
  queued_timeout = var.queued_timeout
  encryption_key = var.encryption_key
  source_version = var.source_version
  tags           = var.tags
}

module "trigger_pull_request" {
  source = "../_internal/trigger"

  stage             = "${local.stage}-pull-request"
  stage_description = local.stage_description
  target_arn        = module.handler.function_arn
  repo_name         = var.repo_name
  event_pattern     = local.event_pattern_pull_request
}

module "trigger_codebuild" {
  source = "../_internal/trigger"

  stage             = "${local.stage}-codebuild"
  stage_description = local.stage_description
  target_arn        = module.handler.function_arn
  repo_name         = var.repo_name
  event_pattern     = local.event_pattern_codebuild
}

resource "aws_lambda_permission" "trigger_pull_request" {
  action        = "lambda:InvokeFunction"
  function_name = module.handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.trigger_pull_request.events_rule_arn
}

resource "aws_lambda_permission" "trigger_codebuild" {
  action        = "lambda:InvokeFunction"
  function_name = module.handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.trigger_codebuild.events_rule_arn
}

# IAM policy documents

data "aws_iam_policy_document" "handler" {
  statement {
    actions   = ["codecommit:PostCommentForPullRequest"]
    resources = [local.repo_arn]
  }

  statement {
    actions   = ["logs:GetLogEvents"]
    resources = [local.codebuild_log_stream_arn]
  }
}
