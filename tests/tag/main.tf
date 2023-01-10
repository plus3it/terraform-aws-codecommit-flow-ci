locals {
  tags = {
    tag1 = {
      repo_name   = "test-tag1-flow-ci"
      policy_arns = []
    }
    tag2 = {
      repo_name   = "test-tag2-flow-ci"
      policy_arns = null
    }
  }
}


module "test_tag" {
  for_each = local.tags
  source   = "../..//modules/tag"

  repo_name   = each.value.repo_name
  policy_arns = each.value.policy_arns

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}
