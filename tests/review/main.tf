module "test_review" {
  source = "../..//modules/review"

  repo_name = local.repo_name

  badge_enabled  = true
  build_timeout  = 20
  queued_timeout = 60
  tags = {
    Test = "True"
  }


  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}

locals {
  repo_name = "test-review-flow-ci"
}
