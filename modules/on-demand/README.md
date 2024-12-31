# terraform-aws-codecommit-flow-ci/on-demand

Trigger a build on demand.

<!-- BEGIN TFDOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12 |

## Providers

No providers.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | Name of the CodeCommit repository | `string` | n/a | yes |
| <a name="input_artifacts"></a> [artifacts](#input\_artifacts) | Map defining an artifacts object for the CodeBuild job | `map(string)` | `{}` | no |
| <a name="input_badge_enabled"></a> [badge\_enabled](#input\_badge\_enabled) | Generates a publicly-accessible URL for the projects build badge | `bool` | `null` | no |
| <a name="input_build_timeout"></a> [build\_timeout](#input\_build\_timeout) | How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed | `number` | `null` | no |
| <a name="input_buildspec"></a> [buildspec](#input\_buildspec) | Buildspec used when a tag reference is created or updated | `string` | `""` | no |
| <a name="input_encryption_key"></a> [encryption\_key](#input\_encryption\_key) | The AWS Key Management Service (AWS KMS) customer master key (CMK) to be used for encrypting the build project's build output artifacts | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Map describing the environment object for the CodeBuild job | `map(string)` | `{}` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | List of environment variable map objects for the CodeBuild job | `list(map(string))` | `[]` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix to attach to repo name | `string` | `""` | no |
| <a name="input_policy_arns"></a> [policy\_arns](#input\_policy\_arns) | List of IAM policy ARNs to attach to the CodeBuild service role or null to support ignoring externally attached policies | `list(string)` | `[]` | no |
| <a name="input_policy_override"></a> [policy\_override](#input\_policy\_override) | IAM policy document in JSON that extends the basic inline CodeBuild service role | `string` | `""` | no |
| <a name="input_queued_timeout"></a> [queued\_timeout](#input\_queued\_timeout) | How long in minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out | `number` | `null` | no |
| <a name="input_source_version"></a> [source\_version](#input\_source\_version) | A version of the build input to be built for this project. If not specified, the latest version is used | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | Object of inputs for the VPC configuration of the CodeBuild job | <pre>object({<br/>    security_group_ids = list(string)<br/>    subnets            = list(string)<br/>    vpc_id             = string<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codebuild_project_arn"></a> [codebuild\_project\_arn](#output\_codebuild\_project\_arn) | ARN of the CodeBuild Project |
| <a name="output_codebuild_project_name"></a> [codebuild\_project\_name](#output\_codebuild\_project\_name) | Name of the CodeBuild Project |
| <a name="output_codebuild_project_service_role"></a> [codebuild\_project\_service\_role](#output\_codebuild\_project\_service\_role) | ARN of the CodeBuild Project Service Role |

<!-- END TFDOCS -->
