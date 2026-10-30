# Agent Instructions

Before starting any task in this repository:

1. Run `make agents/sync`. It writes the shared Plus3 IT instructions for this repository's tardigrade-ci version to `.agents/plus3it/AGENTS.md`.
2. Read `.agents/plus3it/AGENTS.md` and follow it together with this file. If the sync fails, tell the user, and don't guess the conventions.

These rules always apply, even without the shared instructions:

- Don't push, open pull requests, publish releases, or apply infrastructure changes unless the user asks. List those steps for a person in your final report.
- Don't edit files under `.agents/plus3it/`; they are generated and overwritten by the sync.

@.agents/plus3it/AGENTS.md

## Repository-specific

### Purpose

This Terraform module implements an event-based CI workflow on an AWS CodeCommit repository. For each supported event (a pull request opened or updated, a branch updated, a tag created or updated, a schedule, or on demand), it creates a CodeBuild project. For all events except on-demand, it also creates a CloudWatch Events rule and a Lambda function that start the build.

### Module-specific files

- `modules/branch/`, `modules/review/`, `modules/schedule/`, `modules/tag/`, `modules/on-demand/` — Public submodules, one per event type; the top-level module wraps them
- `modules/_internal/` — Internal submodules (`handler`, `runner`, `trigger`) shared by the event modules; `handler` contains the Lambda function source

### Deviations from the terraform-module profile

- There is no `CHANGELOG.md`, so skip the CHANGELOG entry in the profile's interface-change steps. `.bumpversion.cfg` and `release.yml` exist, so still run `make bumpversion/<part>`.
