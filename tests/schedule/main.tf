locals {
  schedules = {
    "test-schedule-flow-ci"  = []
    "test2-schedule-flow-ci" = null
  }
}

module "test_schedule" {
  for_each = local.schedules
  source   = "../..//modules/schedule"

  repo_name   = each.key
  policy_arns = each.value

  schedule_expression = "cron(0 11 ? * MON-FRI *)"

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}
