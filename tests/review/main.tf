module "test_review" {
  source = "../..//modules/review"

  repo_name = local.repo_name

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}

locals {
  repo_name = "test-review-flow-ci"
}
