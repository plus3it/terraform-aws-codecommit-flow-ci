locals {
  branches = {
    "test-branch-flow-ci"  = []
    "test2-branch-flow-ci" = null
  }
}
module "test_branch" {
  for_each = local.branches
  source   = "../../"

  event       = "branch"
  branch      = "master"
  repo_name   = each.key
  policy_arns = each.value

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
                "Resource": "arn:${data.aws_partition.current.partition}:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${each.key}",
                "Sid": ""
            }
        ]
    }
    OVERRIDE
}

locals {
  reviews = {
    "test-review-flow-ci"  = []
    "test2-review-flow-ci" = null
  }
}
module "test_review" {
  for_each = local.reviews
  source   = "../../"

  event          = "review"
  repo_name      = each.key
  policy_arns    = each.value
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

locals {
  schedules = {
    "schedule_repo_name"  = []
    "schedule2_repo_name" = null
  }
}
module "test_schedule" {
  for_each = local.schedules
  source   = "../../"

  event       = "schedule"
  repo_name   = each.key
  policy_arns = each.value

  schedule_expression = "cron(0 11 ? * MON-FRI *)"

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}

locals {
  tags = {
    "test-tag-flow-ci"  = []
    "test2-tag-flow-ci" = null
  }
}
module "test_tag" {
  for_each = local.tags
  source   = "../../"

  event       = "tag"
  repo_name   = each.key
  policy_arns = each.value

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
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
