# terraform-aws-codecommit-releases

Tag an AWS CodeCommit repo when the version is incremented in the default
branch.

Tags are often used to mark a release, but the version is often maintained in a
file in the repo. This project helps automate the creation of the tag, based on
changes to such a file.

This Terraform module creates a CloudWatch Event and a CodeBuild Project. The
Event triggers the CodeBuild Project whenever the repo's default branch is
updated (`referenceUpdated`). The CodeBuild Job checks the version, and creates
a tag if the version has incremented.

## Usage

The version detection can be controlled through the variables:

* `prior_version_command` - Command that returns the prior version
* `release_version_command` - Command that returns the release version

Versions are compared according to Semantic Versioning. If the prior_version
command returns `1.0.0` and the release_version command returns `1.0.1`, then
the tag `1.0.1` would be created on the default branch HEAD.

```hcl
module "codecommit-releases" {
  source = "git::https://github.com/plus3it/terraform-aws-codecommit-releases.git"

  codecommit_repo_name    = "foo"  # This is the only required parameter
  default_branch          = "master"
  prior_version_command   = "git describe --abbrev=0 --tags"
  release_version_command = "grep '^current_version' $CODEBUILD_SRC_DIR/.bumpversion.cfg | sed 's/^.*= //'"
}
```

## Limitations

### Default Branch

The branch to trigger on can be specified using the variable `default_branch`,
but the Cloudwatch Event cannot pass params to the CodeBuild job. That means
the CodeBuild job will only execute on the actual default branch.

If you specify a branch other than the default, the Event will trigger the job
on changes to that non-default branch, but CodeBuild will still pull the actual
default branch.

Changes to the version file in the non-default branch will not result in a new
tag.

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
