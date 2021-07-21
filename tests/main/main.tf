module "test_branch" {
  source = "../../"

  event     = "branch"
  branch    = "master"
  repo_name = local.branch_repo_name

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }

  policy_override = <<-OVERRIDE
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "codecommit:GitPush",
                "Condition": {
                    "StringLikeIfExists": {
                        "codecommit:References": [
                            "refs/tags/*"
                        ]
                    }
                },
                "Effect": "Allow",
                "Resource": "arn:${data.aws_partition.current.partition}:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.branch_repo_name}",
                "Sid": ""
            }
        ]
    }
    OVERRIDE
}

module "test_review" {
  source = "../../"

  event     = "review"
  repo_name = local.review_repo_name

  badge_enabled  = true
  build_timeout  = 20
  queued_timeout = 60
  tags = {
    Test = "True"
  }

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}

module "test_schedule" {
  source = "../../"

  event     = "schedule"
  repo_name = local.schedule_repo_name

  schedule_expression = "cron(0 11 ? * MON-FRI *)"

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}

module "test_tag" {
  source = "../../"

  event     = "tag"
  repo_name = local.tag_repo_name

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}

locals {
  branch_repo_name   = "test-branch-flow-ci"
  review_repo_name   = "test-review-flow-ci"
  schedule_repo_name = "test-schedule-flow-ci"
  tag_repo_name      = "test-tag-flow-ci"
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

output "test_branch" {
  value = module.test_branch
}

output "test_review" {
  value = module.test_review
}

output "test_schedule" {
  value = module.test_schedule
}

output "test_tag" {
  value = module.test_tag
}
