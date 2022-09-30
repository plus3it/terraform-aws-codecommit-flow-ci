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
  source   = "../..//modules/review"

  repo_name   = each.value.repo_name
  policy_arns = each.value.policy_arns

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

