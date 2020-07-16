# terraform-aws-codecommit-flow-ci/review

Trigger a build when a CodeCommit pull request is updated.

<!-- BEGIN TFDOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| repo\_name | Name of the CodeCommit repository | `string` | n/a | yes |
| artifacts | Map defining an artifacts object for the CodeBuild job | `map(string)` | `{}` | no |
| badge\_enabled | Generates a publicly-accessible URL for the projects build badge | `bool` | `null` | no |
| build\_timeout | How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed | `number` | `null` | no |
| buildspec | Buildspec used when a pull request is created or updated | `string` | `""` | no |
| encryption\_key | The AWS Key Management Service (AWS KMS) customer master key (CMK) to be used for encrypting the build project's build output artifacts | `string` | `null` | no |
| environment | Map describing the environment object for the CodeBuild job | `map(string)` | `{}` | no |
| environment\_variables | List of environment variable map objects for the CodeBuild job | `list(map(string))` | `[]` | no |
| policy\_arns | List of IAM policy ARNs to attach to the CodeBuild service role | `list(string)` | `[]` | no |
| policy\_override | IAM policy document in JSON that extends the basic inline CodeBuild service role | `string` | `""` | no |
| queued\_timeout | How long in minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out | `number` | `null` | no |
| source\_version | A version of the build input to be built for this project. If not specified, the latest version is used | `string` | `null` | no |
| tags | A map of tags to assign to the resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| codebuild\_project\_arn | ARN of the CodeBuild Project |
| codebuild\_project\_name | Name of the CodeBuild Project |
| codebuild\_project\_service\_role | ARN of the CodeBuild Project Service Role |
| events\_rule\_codebuild\_arn | ARN of the CloudWatch Event Rule for CodeBuild |
| events\_rule\_pull\_request\_rule\_arn | ARN of the CloudWatch Event Rule for Pull Requests |
| lambda\_function\_arn | ARN of the Lambda function |
| lambda\_function\_name | Name of the Lambda function |
| lambda\_role\_arn | ARN of the Lambda IAM Role |
| lambda\_role\_name | Name of the Lambda IAM Role |

<!-- END TFDOCS -->
