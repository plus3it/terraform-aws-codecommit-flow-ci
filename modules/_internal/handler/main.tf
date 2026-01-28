terraform {
  required_version = ">= 0.12"
}

locals {
  name_slug    = "${var.name_prefix}${var.repo_name}-${var.stage}-flow-ci"
  project_name = element(split("/", element(split(":", var.project_arn), 5)), 1)
}

data "aws_iam_policy_document" "lambda" {
  override_policy_documents = compact([var.lambda_policy_override])

  statement {
    actions   = ["codebuild:StartBuild"]
    resources = [var.project_arn]
  }
}

module "handler" {
  source = "git::https://github.com/plus3it/terraform-aws-lambda.git?ref=v8.4.0"

  function_name = local.name_slug
  description   = var.stage_description
  handler       = "lambda.${var.handler}"
  runtime       = var.python_runtime
  timeout       = 300

  // Specify a file or directory for the source code.
  source_path = "${path.module}/lambda.py"

  // Attach a policy.
  policy = {
    json = data.aws_iam_policy_document.lambda.json
  }

  // Add environment variables.
  environment = {
    variables = {
      PROJECT_NAME = local.project_name
    }
  }
}
