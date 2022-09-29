locals {
  branch_repo_name = "test-branch-flow-ci"

  branches = {
    master_branch = {
      branch      = "master"
      policy_arns = []
    }
    test_empty_list = {
      branch      = "test/empty"
      policy_arns = []
    }
    test_null = {
      branch      = "test/null"
      policy_arns = null
    }
  }
}
module "test_branch" {
  for_each = local.branches
  source   = "../../"

  event       = "branch"
  branch      = each.value.branch
  repo_name   = local.branch_repo_name
  policy_arns = each.value.policy_arns

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

locals {
  reviews = {
    review1 = {
      repo_name   = "test-review1-flow-ci"
      policy_arns = []
    }
    review2 = {
      repo_name   = "test-review2-flow-ci"
      policy_arns = null
    }
  }
}
module "test_review" {
  for_each = local.reviews
  source   = "../../"

  event          = "review"
  repo_name      = each.value.repo_name
  policy_arns    = each.value.policy_arns
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
    schedule1 = {
      repo_name   = "test-schedule1-flow-ci"
      policy_arns = []
    }
    schedule2 = {
      repo_name   = "test-schedule2-flow-ci"
      policy_arns = null
    }
  }
}
module "test_schedule" {
  for_each = local.schedules
  source   = "../../"

  event       = "schedule"
  repo_name   = each.value.repo_name
  policy_arns = each.value.policy_arns

  schedule_expression = "cron(0 11 ? * MON-FRI *)"

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}

locals {
  tags = {
    tag1 = {
      repo_name   = "test-tag1-flow-ci"
      policy_arns = []
    }
    tag2 = {
      repo_name   = "test-tag2-flow-ci"
      policy_arns = null
    }
  }
}
module "test_tag" {
  for_each = local.tags
  source   = "../../"

  event       = "tag"
  repo_name   = each.value.repo_name
  policy_arns = each.value.policy_arns

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
