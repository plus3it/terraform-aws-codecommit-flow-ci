data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  name_slug     = "${var.repo_name}-${var.stage}-flow-ci"
  log_group_arn = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.name_slug}"
  repo_arn      = "arn:${data.aws_partition.current.partition}:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.repo_name}"
  repo_url      = "https://git-codecommit.${data.aws_region.current.name}.amazonaws.com/v1/repos/${var.repo_name}"
}

locals {
  # Setup the CodeBuild environment object
  default_environment = {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:8.11.0"
    type         = "LINUX_CONTAINER"
  }

  # hack: <https://github.com/hashicorp/terraform/issues/12453#issuecomment-378033384>
  environment_variables = {
    empty     = "${map()}"
    not_empty = "${map("environment_variable", var.environment_variables)}"
  }

  environment = "${merge(local.default_environment, var.environment, local.environment_variables[length(var.environment_variables) > 0 ? "not_empty" : "empty"])}"
}

locals {
  # Setup the CodeBuild artifacts object
  default_artifacts = {
    type = "NO_ARTIFACTS"
  }

  artifacts = "${merge(local.default_artifacts, var.artifacts)}"
}

locals {
  # Process the buildspec input
  default_buildspec = "buildspec.yaml"

  buildspec = "${var.buildspec == "" ? local.default_buildspec : var.buildspec}"
}

# IAM resources for CodeBuild

data "template_file" "codebuild_policy_override" {
  template = "${var.policy_override}"

  vars {
    repo_name  = "${var.repo_name}"
    partition  = "${data.aws_partition.current.partition}"
    region     = "${data.aws_region.current.name}"
    account_id = "${data.aws_caller_identity.current.account_id}"
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
  override_json = "${data.template_file.codebuild_policy_override.rendered}"

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${local.log_group_arn}",
      "${local.log_group_arn}:*",
    ]
  }

  statement {
    actions   = ["codecommit:GitPull"]
    resources = ["${local.repo_arn}"]
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${local.name_slug}-codebuild-service-role"
  assume_role_policy = "${data.aws_iam_policy_document.codebuild_assume_role.json}"
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${local.name_slug}-codebuild"
  role   = "${aws_iam_role.codebuild.id}"
  policy = "${data.aws_iam_policy_document.codebuild.json}"
}

data "aws_iam_policy" "codebuild" {
  count = "${length(var.policy_arns)}"

  arn = "${element(var.policy_arns, count.index)}"
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  count = "${length(data.aws_iam_policy.codebuild.*.arn)}"

  role       = "${aws_iam_role.codebuild.id}"
  policy_arn = "${element(data.aws_iam_policy.codebuild.*.arn, count.index)}"
}

# CodeBuild Resources

resource "aws_codebuild_project" "this" {
  name         = "${local.name_slug}"
  description  = "${var.stage_description}"
  service_role = "${aws_iam_role.codebuild.arn}"
  artifacts    = ["${local.artifacts}"]
  environment  = ["${local.environment}"]

  source {
    type      = "CODECOMMIT"
    location  = "${local.repo_url}"
    buildspec = "${local.buildspec}"
  }
}
