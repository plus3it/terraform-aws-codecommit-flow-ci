terraform {
  required_version = ">= 0.12"
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
}

locals {
  name_slug     = "${var.name_prefix}${var.repo_name}-${var.stage}-flow-ci"
  log_group_arn = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/codebuild/${local.name_slug}"
  repo_arn      = "arn:${local.partition}:codecommit:${local.region}:${local.account_id}:${var.repo_name}"
  repo_url      = "https://git-codecommit.${local.region}.amazonaws.com/v1/repos/${var.repo_name}"


}

locals {
  # Setup the CodeBuild environment object
  default_environment = {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:4.0"
    type         = "LINUX_CONTAINER"
  }

  environment = merge(local.default_environment, var.environment)
}

locals {
  # Setup the CodeBuild artifacts object
  default_artifacts = {
    type = "NO_ARTIFACTS"
  }

  artifacts = merge(local.default_artifacts, var.artifacts)
}

# IAM resources for CodeBuild

data "template_file" "codebuild_policy_override" {
  template = var.policy_override

  vars = {
    name        = "${var.name_prefix}${var.repo_name}"
    name_prefix = var.name_prefix
    name_slug   = local.name_slug
    partition   = data.aws_partition.current.partition
    region      = data.aws_region.current.region
    repo_name   = var.repo_name
    account_id  = data.aws_caller_identity.current.account_id
  }
}

data "template_file" "policy_arns" {
  count = var.policy_arns != null ? length(var.policy_arns) : 0

  template = var.policy_arns[count.index]

  vars = {
    name        = "${var.name_prefix}${var.repo_name}"
    name_prefix = var.name_prefix
    name_slug   = local.name_slug
    partition   = data.aws_partition.current.partition
    region      = data.aws_region.current.region
    repo_name   = var.repo_name
    account_id  = data.aws_caller_identity.current.account_id
  }
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild" {
  override_policy_documents = compact([data.template_file.codebuild_policy_override.rendered])

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      local.log_group_arn,
      "${local.log_group_arn}:*",
    ]
  }

  statement {
    actions   = ["codecommit:GitPull"]
    resources = [local.repo_arn]
  }

  dynamic "statement" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs",
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      actions = [
        "ec2:CreateNetworkInterfacePermission",
      ]
      resources = ["arn:${local.partition}:ec2:${local.region}:${local.account_id}:network-interface/*"]

      condition {
        test     = "StringEquals"
        variable = "ec2:Subnet"

        values = [
          for subnet in statement.value.subnets :
          "arn:${local.partition}:ec2:${local.region}:${local.account_id}:subnet/${subnet}"
        ]
      }

      condition {
        test     = "StringEquals"
        variable = "ec2:AuthorizedService"

        values = [
          "codebuild.amazonaws.com",
        ]
      }
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name_prefix        = "flow-ci-codebuild-service-role-"
  description        = "${local.name_slug}-codebuild-service-role -- Managed by Terraform"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

# attach inline policy to the codebuild role
resource "aws_iam_role_policy" "codebuild" {
  name   = "${local.name_slug}-codebuild"
  policy = data.aws_iam_policy_document.codebuild.json
  role   = aws_iam_role.codebuild.name
}

# attach managed policies to the codebuild role
resource "aws_iam_role_policy_attachment" "codebuild" {
  for_each = toset(data.template_file.policy_arns)

  role       = aws_iam_role.codebuild.id
  policy_arn = each.value.rendered
}

# CodeBuild Resources
resource "aws_codebuild_project" "this" {
  name         = local.name_slug
  description  = var.stage_description
  service_role = aws_iam_role.codebuild.arn

  badge_enabled  = var.badge_enabled
  build_timeout  = var.build_timeout
  queued_timeout = var.queued_timeout
  encryption_key = var.encryption_key
  source_version = var.source_version
  tags           = var.tags

  dynamic "artifacts" {
    for_each = [local.artifacts]
    content {
      encryption_disabled = lookup(artifacts.value, "encryption_disabled", null)
      location            = lookup(artifacts.value, "location", null)
      name                = lookup(artifacts.value, "name", null)
      namespace_type      = lookup(artifacts.value, "namespace_type", null)
      packaging           = lookup(artifacts.value, "packaging", null)
      path                = lookup(artifacts.value, "path", null)
      type                = artifacts.value.type
    }
  }

  dynamic "environment" {
    for_each = [local.environment]
    content {
      certificate                 = lookup(environment.value, "certificate", null)
      compute_type                = environment.value.compute_type
      image                       = environment.value.image
      image_pull_credentials_type = lookup(environment.value, "image_pull_credentials_type", null)
      privileged_mode             = lookup(environment.value, "privileged_mode", null)
      type                        = environment.value.type

      dynamic "environment_variable" {
        for_each = var.environment_variables
        content {
          name  = environment_variable.value.name
          type  = lookup(environment_variable.value, "type", null)
          value = environment_variable.value.value
        }
      }
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnets            = vpc_config.value.subnets
      vpc_id             = vpc_config.value.vpc_id
    }
  }

  source {
    type      = "CODECOMMIT"
    location  = local.repo_url
    buildspec = var.buildspec
  }

  lifecycle {
    ignore_changes = [project_visibility]
  }
}
