[![pullreminders](https://pullreminders.com/badge.svg)](https://pullreminders.com?ref=badge)

# terraform-aws-codecommit-flow-ci

Implement an event-based CI workflow on a CodeCommit repository.

This project aims to help implement CI/CD git workflows for CodeCommit
repositories. Fundamentally, we want to be able to trigger the CI system
(CodeBuild) when certain events occur in the CodeCommit reopository:

* Pull request opened or source commit modified
* Branch HEAD modified
* Tag created or updated
* Scheduled build (e.g. "cron")

All of the building blocks are there, pull requests, CloudWatch Events, etc,
but understanding the event structures and linking the events to the CI system
is a lot of work. This project makes it easier.

For each event, the user ought to be able to specify what the CI system should
do, what commands should be executed. In CodeBuild, this is accomplished by
using a different buildspec per event. To simplify the implementation of this
project, at the moment, a CodeBuild project is created for each event, and of
course for each CodeBuild project you can specify a different buildspec.

## Public modules

The top-level module is a wrapper around each of the "event" modules. There is
also a public module for each of the events mentioned above:

* [branch](modules/branch)
* [review](modules/review) -- i.e. the pull request event
* [tag](modules/tag)
* [schedule](modules/schedule)

In general, each module sets up the following resources:

* CloudWatch Events
* Lambda
* CodeBuild

When a matching event occurs in the repository, CloudWatch Events triggers the
Lambda function. The Lambda function extracts information from the event, most
critically the source commit, and starts the CodeBuild job.

The `review` module additionally uses CloudWatch Events to monitor the status
of its CodeBuild job executions and comments on the associated pull request
with the status of the CodeBuild job. CodeCommit does not have anything like
the GitHub Status API or Checks API, so these comments at least allow users to
get updates on whether the CI passed/failed right within the pull request.

## A complete example workflow

In this example, we setup the CI to execute automatically on four events:

* A pull request is opened or updated (`review` module)
* The `master` branch is updated (`branch` module)
* A tag is created or updated (`tag` module)
* A weekday schedule (`schedule` module)

We have separate buildspecs for each event-type, and we keep those buildspecs
together in the repository, in the `buildspecs` directory.

In this workflow, someone would open a pull request and the CI would trigger
immediately to execute tests (as defined by `buildspecs/review.yaml`). The CI
would post success/failure of the tests as a pull request comment, and an
approver would make the decision when to merge the work.

Upon merge to the `master` branch, the `branch` CI executes whatever is defined
in `buidspecs/master.yaml`. Imagine there is a test for a condition that we use
to determine when to create a release (such as incrementing a version in a
version file). When that condition is matched, the `branch` buildspec pushes a
tag to the repo with the new version. To grant permission for this CodeBuild
job to push tags to the repo, we pass in the `policy_override` (defined in the `locals` block, in this example).

When the tag is created, the `tag` CI then executes the job as defined by
`buildspecs/tag.yaml` to handle the release. Examples of things a buildspec
might do in this case:

* Publish a package to a repository (PyPI, RubyGems, npm, etc)
* Generate and push artifacts to S3
* Initiate a CodePipeline
* Launch/update a CloudFormation stack
* Run terraform plan/apply
* Etc, etc, whatever constitutes your "release"...

```hcl
module "review" {
  source = "git::https://github.com/plus3it/terraform-aws-codecommit-flow-ci.git"

  event     = "review"
  repo_name = "foo"
  buildspec = "buildspecs/review.yaml"
}

module "branch" {
  source = "git::https://github.com/plus3it/terraform-aws-codecommit-flow-ci.git"

  event     = "branch"
  repo_name = "foo"
  branch    = "master"
  buildspec = "buildspecs/master.yaml"

  policy_override = local.branch_policy_override
}

module "tag" {
  source = "git::https://github.com/plus3it/terraform-aws-codecommit-flow-ci.git"

  event     = "tag"
  repo_name = "foo"
  buildspec = "buildspecs/tag.yaml"
}

module "schedule" {
  source = "git::https://github.com/plus3it/terraform-aws-codecommit-flow-ci.git"

  event     = "schedule"
  repo_name = "foo"
  buildspec = "buildspecs/schedule.yaml"

  schedule_expression = "cron(0 11 ? * MON-FRI *)"
}

locals {
  branch_policy_override = <<-OVERRIDE
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "codecommit:GitPush",
                "Condition": {
                    "StringLikeIfExists": {
                        "codecommit:References": [
                            "refs/tags/*"
                        ]
                    }
                },
                "Effect": "Allow",
                "Resource": "arn:<partition>:codecommit:<region>:<account-id>:foo",
                "Sid": ""
            }
        ]
    }
    OVERRIDE
}
```

### `buildspec` variable object

The `buildspec` variable object is a string that can be either a relative path
in the repository to the buildspec file (e.g. `buildspec.yaml`), or a complete
multi-line string buildspec specification.

The default is the file `buildspec.yaml`, which would need to be present in
the root of your CodeCommit repository. If the file is missing, the job will
simply error.

To use a multi-line string as a buildspec, see the example below. This
specification contains no commands and so actually does nothing:

```hcl
buildspec = <<-BUILDSPEC
  version: 0.2
  phases: {}
  BUILDSPEC
```

See the [AWS CodeBuild docs][codebuild-buildspec] for a complete description
of the buildspec specification.

[codebuild-buildspec]: https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html#build-spec-ref-syntax

### `artifacts` variable object

The `artifacts` variable is a map that is passed through to the `artifacts`
option of the Terraform `aws_codebuild_project` resource. It defaults to:

```hcl
artifacts = {
  type = "NO_ARTIFACTS"
}
```

See the [Terraform resource docs][terraform-codebuild-artifacts] for all the
available options.

[terraform-codebuild-artifacts]: https://www.terraform.io/docs/providers/aws/r/codebuild_project.html#artifacts

### `environment` variable object

The `environment` variable is a map that is passed through to the `environment`
option of the Terraform `aws_codebuild_project` resource. It defaults to:

```hcl
environment = {
  compute_type = "BUILD_GENERAL1_SMALL"
  image        = "aws/codebuild/nodejs:8.11.0"
  type         = "LINUX_CONTAINER"
}
```

See the [Terraform resource docs][terraform-codebuild-environment] for all the
available options.

[terraform-codebuild-environment]: https://www.terraform.io/docs/providers/aws/r/codebuild_project.html#environment

### `environment_variables` variable object

The `environment_variables` variable is a list of environment variable map
objects that is merged into to the `environment` object (described above). It
defaults to an empty list, meaning no environment variables. Example:

```hcl
environment_variables = [
  {
    name  = "FOO"
    value = "foo"
  },
  {
    name  = "BAR"
    value = "bar"
  }
]
```

See the [Terraform resource docs][terraform-codebuild-environment] for a more
thorough description of the options for the environment variable map object.

### `policy_arns` variable object

The `policy_arns` variable is a list of IAM policy ARNs to attach to the
CodeBuild service role, or null to support ignoring externally attached policies
Example:

```hcl
policy_arns = [
  "arn:<partition>:iam::<account>:policy/foo",
  "arn:<partition>:iam::<account>:policy/bar"
]
```

```hcl
policy_arns = null
```

### `policy_override` variable object

The `policy_override` variable is an IAM policy document in JSON that extends
the builtin CodeBuild service role. This option is provided as an alternative
to creating an IAM managed policy and passing the policy through `policy_arns`.
It is a convenient way to grant a small number of additional permissions to a
single CI job. Example:

```hcl
policy_override = <<-OVERRIDE
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "codecommit:GitPush",
              "Condition": {
                  "StringLikeIfExists": {
                      "codecommit:References": [
                          "refs/tags/*"
                      ]
                  }
              },
              "Effect": "Allow",
              "Resource": "arn:<partition>:codecommit:<region>:<account-id>:foo",
              "Sid": ""
          }
      ]
  }
  OVERRIDE
```

## CodeBuild environment variable injection

The Lambda function for each event injects one or more environment variables
into the corresponding CodeBuild job, using information from the event that
invoked the function. These variables are available in the job environment, and
so you may reference them from your buildspecs.

* `review`
  * `FLOW_PULL_REQUEST_ID`: ID of the pull request that triggered the event
  * `FLOW_PULL_REQUEST_SRC_COMMIT`: SHA of the source commit in the pull
        request
  * `FLOW_PULL_REQUEST_DST_COMMIT`: SHA of the destination commit (the
        target branch) in the pull request
* `branch`
  * `FLOW_BRANCH`: Name of the branch that triggered the event
* `tag`
  * `FLOW_TAG`: Name of the tag that triggered the event
* `schedule`
  * `FLOW_SCHEDULE`: Time associated with the scheduled event

## Builtin CodeBuild service role

A default service role will be created for each CodeBuild job. The service role
has just enough permissions to create and write to the job's CloudWatch Log
Group, and to clone the CodeCommit repository. This service role can be
extended using the `policy_arns` or `policy_override` variables.

```hcl
statement {
  actions = [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents",
  ]

  resources = [
    "arn:<partition>:logs:<region>:<account-id>:log-group:/aws/codebuild/${local.name_slug}",
    "arn:<partition>:logs:<region>:<account-id>:log-group:/aws/codebuild/${local.name_slug}:*",
  ]
}

statement {
  actions   = ["codecommit:GitPull"]
  resources = ["arn:<partition>:codecommit:<region>:<account-id>:${var.repo_name}"]
}
```

## Builtin Lambda service role

A default service role will be created for each Lambda function. The service
role has just enough permissions to create and write to the function's
CloudWatch Log Group, and to start the CodeBuild job. There are no user
variables exposed that extend or modify this role.

```hcl
statement {
  actions = [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents",
  ]

  resources = [
    "arn:<partition>:logs:<region>:<account-id>:log-group:/aws/lambda/${local.name_slug}",
    "arn:<partition>:logs:<region>:<account-id>:log-group:/aws/lambda/${local.name_slug}:*",
  ]
}

statement {
  actions   = ["codebuild:StartBuild"]
  resources = ["arn:<partition>:codebuild:<region>:<account-id>:project/${local.name_slug}"]
}
```

In addition, the `review` module extends the Lambda service role with
permissions that allow the function to post comments to the pull request, and
to retrieve logs from the CodeBuild job (for inclusion in the pull request
comment).

```hcl
statement {
  actions   = ["codecommit:PostCommentForPullRequest"]
  resources = ["arn:<partition>:codecommit:<region>:<account-id>:${var.repo_name}"]
}

statement {
  actions   = ["logs:GetLogEvents"]
  resources = ["arn:<partition>:logs:<region>:<account-id>:log-group:/aws/codebuild/${var.repo_name}-review-flow-ci:log-stream:*"]
}
```

## Testing

At the moment, testing is manual:

```
# Replace "xxx" with an actual AWS profile, then execute the integration tests.
export AWS_PROFILE=xxx
make terraform/pytest PYTEST_ARGS="-v --nomock"
```

## Authors

This module is managed by [Plus3 IT Systems](https://github.com/plus3it).

## License

Apache 2 licensed. See [LICENSE](LICENSE) for details.

<!-- BEGIN TFDOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.28.0 |

## Providers

No providers.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_event"></a> [event](#input\_event) | Type of event that will trigger the flow-ci job | `string` | n/a | yes |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | Name of the CodeCommit repository | `string` | n/a | yes |
| <a name="input_artifacts"></a> [artifacts](#input\_artifacts) | Map defining an artifacts object for the CodeBuild job | `map(string)` | `{}` | no |
| <a name="input_badge_enabled"></a> [badge\_enabled](#input\_badge\_enabled) | Generates a publicly-accessible URL for the projects build badge | `bool` | `null` | no |
| <a name="input_branch"></a> [branch](#input\_branch) | Name of the branch where updates will trigger a build. Used only when `event` is "branch" | `string` | `null` | no |
| <a name="input_build_timeout"></a> [build\_timeout](#input\_build\_timeout) | How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed | `number` | `null` | no |
| <a name="input_buildspec"></a> [buildspec](#input\_buildspec) | Buildspec used when the specified branch is updated | `string` | `""` | no |
| <a name="input_encryption_key"></a> [encryption\_key](#input\_encryption\_key) | The AWS Key Management Service (AWS KMS) customer master key (CMK) to be used for encrypting the build project's build output artifacts | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Map describing the environment object for the CodeBuild job | `map(string)` | `{}` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | List of environment variable map objects for the CodeBuild job | `list(map(string))` | `[]` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix to attach to repo name | `string` | `""` | no |
| <a name="input_policy_arns"></a> [policy\_arns](#input\_policy\_arns) | List of IAM policy ARNs to attach to the CodeBuild service role | `list(string)` | `[]` | no |
| <a name="input_policy_override"></a> [policy\_override](#input\_policy\_override) | IAM policy document in JSON that extends the basic inline CodeBuild service role | `string` | `""` | no |
| <a name="input_python_runtime"></a> [python\_runtime](#input\_python\_runtime) | Python runtime for the handler Lambda function | `string` | `null` | no |
| <a name="input_queued_timeout"></a> [queued\_timeout](#input\_queued\_timeout) | How long in minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out | `number` | `null` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | CloudWatch Event schedule that triggers the CodeBuild job. Required when `event` is "schedule" | `string` | `null` | no |
| <a name="input_source_version"></a> [source\_version](#input\_source\_version) | A version of the build input to be built for this project. If not specified, the latest version is used | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | Object of inputs for the VPC configuration of the CodeBuild job | <pre>object({<br>    security_group_ids = list(string)<br>    subnets            = list(string)<br>    vpc_id             = string<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_branch"></a> [branch](#output\_branch) | Outputs from the branch module |
| <a name="output_review"></a> [review](#output\_review) | Outputs from the review module |
| <a name="output_schedule"></a> [schedule](#output\_schedule) | Outputs from the schedule module |
| <a name="output_tag"></a> [tag](#output\_tag) | Outputs from the tag module |

<!-- END TFDOCS -->
