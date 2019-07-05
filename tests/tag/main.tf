module "test_tag" {
  source = "../..//modules/tag"

  repo_name = local.repo_name

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}

locals {
  repo_name = "test-tag-flow-ci"
}
