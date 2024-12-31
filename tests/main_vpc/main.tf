locals {
  branch_repo_name = "test-branch-flow-ci"

  branches = {
    master_branch = {
      branch      = "master"
      policy_arns = []
    }
  }
}

module "test_branch" {
  for_each = local.branches
  source   = "../../"

  name_prefix = "tardigrade-vpc-"
  event       = "branch"
  branch      = each.value.branch
  repo_name   = local.branch_repo_name
  policy_arns = each.value.policy_arns
  vpc_config  = local.vpc_config

  environment = {
    compute_type = "BUILD_GENERAL1_SMALL"
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

  name_prefix    = "tardigrade-vpc-"
  event          = "review"
  repo_name      = each.value.repo_name
  policy_arns    = each.value.policy_arns
  badge_enabled  = true
  build_timeout  = 20
  queued_timeout = 60
  vpc_config     = local.vpc_config

  tags = {
    Test = "True"
  }

  environment = {
    compute_type = "BUILD_GENERAL1_SMALL"
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

  name_prefix = "tardigrade-vpc-"
  event       = "schedule"
  repo_name   = each.value.repo_name
  policy_arns = each.value.policy_arns
  vpc_config  = local.vpc_config

  schedule_expression = "cron(0 11 ? * MON-FRI *)"

  environment = {
    compute_type = "BUILD_GENERAL1_SMALL"
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

  name_prefix = "tardigrade-vpc-"
  event       = "tag"
  repo_name   = each.value.repo_name
  policy_arns = each.value.policy_arns
  vpc_config  = local.vpc_config

  environment = {
    compute_type = "BUILD_GENERAL1_SMALL"
  }
}

locals {
  vpc_config = {
    vpc_id = aws_vpc.test.id
    security_group_ids = [
      aws_security_group.test.id
    ]
    subnets = [
      for subnet in aws_subnet.test : subnet.id
    ]
  }
}

resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Test = "Tardigrade - terraform-aws-code-commit-flow-ci/main_vpc"
  }
}

resource "aws_subnet" "test" {
  for_each = toset(["10.0.0.0/24", "10.0.1.0/24"])

  vpc_id     = aws_vpc.test.id
  cidr_block = each.value
  tags = {
    Test = "Tardigrade - terraform-aws-code-commit-flow-ci/main_vpc"
  }
}

resource "aws_security_group" "test" {
  name        = "allow_vpc_cidr"
  description = "Tardigrade - terraform-aws-code-commit-flow-ci/main_vpc"
  vpc_id      = aws_vpc.test.id

  ingress {
    description = "Tardigrade - terraform-aws-code-commit-flow-ci/main_vpc"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.test.cidr_block]
  }

  egress {
    description      = "Tardigrade - terraform-aws-code-commit-flow-ci/main_vpc"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Test = "Tardigrade - terraform-aws-code-commit-flow-ci/main_vpc"
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
