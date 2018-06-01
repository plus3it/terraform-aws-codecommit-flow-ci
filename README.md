# terraform-aws-codecommit-releases

Tag an AWS CodeCommit repo when the version is incremented in the release
branch.

Tags are often used to mark a release, but the version is often maintained in a
file in the repo. This project helps automate the creation of the tag, based on
changes to such a file.

This Terraform module creates a CloudWatch Event and a CodeBuild Project. The
Event triggers the CodeBuild Project whenever the repo's release branch is
updated (`referenceUpdated`). The CodeBuild Job checks the version, and creates
a tag if the version has incremented.

## Version detection

The version detection can be controlled through the variables:

*   `prior_version_command` - Command that returns the prior version
*   `release_version_command` - Command that returns the release version

Versions are compared according to Semantic Versioning. For example, if
`prior_version_command` returns `1.0.0` and `release_version_command` returns
`1.0.1`, then the tag `1.0.1` would be created on the `release_branch` HEAD.

## Running commands

If you need to run any _build_ commands on _every_ update to the release
branch, pass a list of commands in the `build_commands` variable. The commands
will be injected into the buildspec, prior to testing whether the version has
incremented.

If you need to run any _release_ commands, **only** if the version has
incremented, pass a list of commands in the `release_commands` variable. The
commands will be injected into the buildspec, just prior to tagging the release
branch. The _release_ commands execute _only_ in the case of a release, when
the version has been incremented.

The _release_ commands are executed inside a multi-line if statement, so if you
need them to errexit on failure, append ` || exit $?` to the command in the
`release_commands` list to force the shell to exit non-zero. This is not
needed for `build_commands`; they always errexit.

## Attaching extra IAM policies

The module creates a CodeBuild service role with an inline policy that has the
minimum permissions needed to clone and push tags to the CodeCommit repo.
However, commands specified using `build_commands` or `release_commands` may
use additional AWS resources and require additional permissions. This use case
can be addressed through the `iam_policies` variable. Create the IAM policies
separately, and pass a list of policy ARNs through this variable. The policies
will be attached to the CodeBuild service role, so the job will have the
permissions needed by the extra commands.

## Example

```hcl
module "codecommit-releases" {
  source = "git::https://github.com/plus3it/terraform-aws-codecommit-releases.git"

  codecommit_repo_name    = "foo"  # This is the only required parameter
  release_branch          = "master"
  prior_version_command   = "git describe --abbrev=0 --tags"
  release_version_command = "grep '^current_version' $CODEBUILD_SRC_DIR/.bumpversion.cfg | sed 's/^.*= //'"

  build_commands = [
    "echo foo"
  ]

  release_commands = [
    "echo bar || exit $?"
  ]

  iam_policies = [
    "arn:aws:iam::<account>:policy/<policy-name>"
  ]
}
```

## Limitations

### Semantic Versioning

This project only supports versioning schemes that comply with Semantic
Versioning. If the repo does not use Semantic Versioning, no tag will be
created. You can use the [`semver` utility][semver] yourself to determine
whether your versioning scheme will work.

[semver]: https://docs.npmjs.com/misc/semver

## Authors

This module is managed by [Plus3 IT Systems](https://github.com/plus3it).

## License

Apache 2 licensed. See [LICENSE](LICENSE) for details.
