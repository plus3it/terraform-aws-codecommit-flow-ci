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
  source   = "../..//modules/schedule"

  repo_name   = each.value.repo_name
  policy_arns = each.value.policy_arns

  schedule_expression = "cron(0 11 ? * MON-FRI *)"

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}
