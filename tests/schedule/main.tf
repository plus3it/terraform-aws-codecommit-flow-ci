module "test_schedule" {
  source = "../..//modules/schedule"

  repo_name = local.repo_name

  schedule_expression = "cron(0 11 ? * MON-FRI *)"

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}

locals {
  repo_name = "test-schedule-flow-ci"
}
