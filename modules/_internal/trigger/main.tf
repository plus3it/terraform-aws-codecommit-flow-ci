locals {
  name_slug = "${var.repo_name}-${var.stage}-flow-ci"
}

# CloudWatch Event Resources

resource "aws_cloudwatch_event_rule" "this" {
  name                = "${local.name_slug}"
  description         = "${var.stage_description}"
  event_pattern       = "${var.event_pattern}"
  schedule_expression = "${var.schedule_expression}"
}

resource "aws_cloudwatch_event_target" "this" {
  rule = "${aws_cloudwatch_event_rule.this.name}"
  arn  = "${var.target_arn}"
}
