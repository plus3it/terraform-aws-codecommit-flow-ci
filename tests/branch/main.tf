module "test_branch" {
  source = "../..//modules/branch"

  repo_name = local.repo_name
  branch    = "master"

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
                "Resource": "arn:${data.aws_partition.current.partition}:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.repo_name}",
                "Sid": ""
            }
        ]
    }
    OVERRIDE
}


locals {
  branches = {
    "test/dev"  = []
    "test/dev2" = null
  }
}
module "test_branch2" {
  for_each = local.branches
  source   = "../..//modules/branch"

  repo_name   = local.repo_name
  branch      = each.key
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
                "Resource": "arn:${data.aws_partition.current.partition}:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.repo_name}",
                "Sid": ""
            }
        ]
    }
    OVERRIDE
}

locals {
  repo_name = "test-branch-flow-ci"
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
