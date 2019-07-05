[![pullreminders](https://pullreminders.com/badge.svg)](https://pullreminders.com?ref=badge)

# terraform-aws-codecommit-flow-ci

Implement an event-based CI workflow on a CodeCommit repository.

This project aims to help implement CI/CD git workflows for CodeCommit
repositories. Fundamentally, we want to be able to trigger the CI system
(CodeBuild) when certain events occur in the CodeCommit reopository:

*   Pull request opened or source commit modified
*   Branch HEAD modified
*   Tag created or updated
*   Scheduled build (e.g. "cron")

All of the building blocks are there, pull requests, CloudWatch Events, etc,
but understanding the event structures and linking the events to the CI system
is a lot of work. This project makes it easier.

For each event, the user ought to be able to specify what the CI system should
do, what commands should be executed. In CodeBuild, this is accomplished by
using a different buildspec per event. To simplify the implementation of this
project, at the moment, a CodeBuild project is created for each event, and of
course for each CodeBuild project you can specify a different buildspec.

## Public modules

There is a public module for each of the events mentioned above:

*   [branch](modules/branch)
*   [review](modules/review) -- i.e. the pull request event
*   [tag](modules/tag)
*   [schedule](modules/schedule)

In general, each module sets up the following resources:

*   CloudWatch Events
*   Lambda
*   CodeBuild

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

*   A pull request is opened or updated (`review` module)
*   The `master` branch is updated (`branch` module)
*   A tag is created or updated (`tag` module)
*   A weekday schedule (`schedule` module)

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

*   Publish a package to a repository (PyPI, RubyGems, npm, etc)
*   Generate and push artifacts to S3
*   Initiate a CodePipeline
*   Launch/update a CloudFormation stack
*   Run terraform plan/apply
*   Etc, etc, whatever constitutes your "release"...

```hcl
module "review" {
  source = "git::https://github.com/plus3it/terraform-aws-codecommit-flow-ci.git//modules/review"

  repo_name = "foo"
  buildspec = "buildspecs/review.yaml"
}

module "branch" {
  source = "git::https://github.com/plus3it/terraform-aws-codecommit-flow-ci.git//modules/branch"

  repo_name = "foo"
  branch    = "master"
  buildspec = "buildspecs/master.yaml"

  policy_override = local.branch_policy_override
}

module "tag" {
  source = "git::https://github.com/plus3it/terraform-aws-codecommit-flow-ci.git//modules/tag"

  repo_name = "foo"
  buildspec = "buildspecs/tag.yaml"
}

module "schedule" {
  source = "git::https://github.com/plus3it/terraform-aws-codecommit-flow-ci.git//modules/schedule"

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

## Variables

| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `repo_name` | Name of the CodeCommit repository | string | - |
| `branch` | Name of the branch that will trigger a build; used only by the `branch` module | string | `master` |
| `buildspec` | Buildspec used by the CodeBuild job; may be a relative path to a file, or a complete buildspec as a multi-line string | string | `""` |
| `artifacts` | Map defining the artifacts object for the CodeBuild job | map | `{}` |
| `environment` | Map defining the environment object for the CodeBuild job | map | `{}` |
| `environment_variables` | List of environment variable map objects for the CodeBuild job | list of maps | `[]` |
| `policy_arns` | List of IAM policy ARNs to attach to the CodeBuild service role | list | `[]` |
| `policy_override` | IAM policy document in JSON that overrides/extends the builtin CodeBuild service role | string | `""` |
| `schedule_expression` | CloudWatch Event schedule that triggers the CodeBuild job; used only be the `schedule` module | string | `""` |

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
CodeBuild service role. Example:

```hcl
policy_arns = [
  "arn:<partition>:iam::<account>:policy/foo",
  "arn:<partition>:iam::<account>:policy/bar"
]
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

*   `review`
    *   `FLOW_PULL_REQUEST_ID`: ID of the pull request that triggered the event
    *   `FLOW_PULL_REQUEST_SRC_COMMIT`: SHA of the source commit in the pull
        request
    *   `FLOW_PULL_REQUEST_DST_COMMIT`: SHA of the destination commit (the
        target branch) in the pull request
*   `branch`
    *   `FLOW_BRANCH`: Name of the branch that triggered the event
*   `tag`
    *   `FLOW_TAG`: Name of the tag that triggered the event
*   `schedule`
    *   `FLOW_SCHEDULE`: Time associated with the scheduled event

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

## Authors

This module is managed by [Plus3 IT Systems](https://github.com/plus3it).

## License

Apache 2 licensed. See [LICENSE](LICENSE) for details.
