locals {
  reviews = {
    "test-review-flow-ci" = []
  }
}

module "test_review" {
  for_each = local.reviews
  source   = "../..//modules/review"

  repo_name   = each.key
  policy_arns = each.value

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

