locals {
  repo_name = "test-branch-flow-ci"

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
  source   = "../../modules/branch"

  name_prefix = "tardigrade-"
  repo_name   = local.repo_name
  branch      = each.value.branch
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
                "Resource": "arn:${data.aws_partition.current.partition}:codecommit:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${local.repo_name}",
                "Sid": ""
            }
        ]
    }
    OVERRIDE
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
