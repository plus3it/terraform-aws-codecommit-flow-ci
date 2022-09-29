locals {
  tags = {
    "test-tag-flow-ci"  = []
    "test2-tag-flow-ci" = null
  }
}

module "test_tag" {
  for_each = local.tags
  source   = "../..//modules/tag"

  repo_name   = each.key
  policy_arns = each.value

  environment = {
    compute_type = "BUILD_GENERAL1_LARGE"
  }
}

