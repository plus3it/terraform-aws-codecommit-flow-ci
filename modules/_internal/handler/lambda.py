"""Lambda handlers that implement an event-based CI workflow for CodeCommit."""
import collections
import json
import logging
import os
import urllib.parse

import boto3

DEFAULT_LOG_LEVEL = logging.INFO
LOG_LEVELS = collections.defaultdict(
    lambda: DEFAULT_LOG_LEVEL,
    {
        "critical": logging.CRITICAL,
        "error": logging.ERROR,
        "warning": logging.WARNING,
        "info": logging.INFO,
        "debug": logging.DEBUG,
    },
)

# Lambda initializes a root logger that needs to be removed in order to set a
# different logging config
root = logging.getLogger()
if root.handlers:
    for handler in root.handlers:
        root.removeHandler(handler)

logging.basicConfig(
    format="%(asctime)s.%(msecs)03dZ [%(name)s][%(levelname)-5s]: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    level=LOG_LEVELS[os.environ.get("LOG_LEVEL", "").lower()],
)
log = logging.getLogger(__name__)

codebuild = boto3.client("codebuild")
codecommit = boto3.client("codecommit")
cloudwatchlogs = boto3.client("logs")

PROJECT_NAME = os.environ["PROJECT_NAME"]


def dump_json(data, indent=2, **opts):
    """Dump JSON output with custom, localized defaults."""
    return json.dumps(data, indent=indent, **opts)


def start_build(params):
    """Start a CodeBuild job."""
    log.info("Sending request to StartBuild...")
    log.debug("StartBuild params:\n%s", params)
    response = codebuild.start_build(**params)
    log.info("StartBuild succeeded!")
    log.debug("StartBuild response:\n%s", response)
    return response


def post_comment(params):
    """Post a comment to a CodeCommit pull request."""
    log.info("Sending request to PostComment...")
    log.debug("PostComment params:\n%s", params)
    response = codecommit.post_comment_for_pull_request(**params)
    log.info("PostComment succeeded!")
    log.debug("PostComment response:\n%s", response)
    return response


def handle_codebuild_review_event(event):  # pylint: disable=too-many-locals
    """Gather build details and post a comment to a managed pull request."""
    event_details = event["detail"]
    additional_information = event_details["additional-information"]
    environment = additional_information["environment"]
    environment_variables = environment["environment-variables"]

    pull_request_id = [
        env["value"]
        for env in environment_variables
        if env["name"] == "FLOW_PULL_REQUEST_ID"
    ]
    source_commit = [
        env["value"]
        for env in environment_variables
        if env["name"] == "FLOW_PULL_REQUEST_SRC_COMMIT"
    ]
    destination_commit = [
        env["value"]
        for env in environment_variables
        if env["name"] == "FLOW_PULL_REQUEST_DST_COMMIT"
    ]

    if pull_request_id and source_commit and destination_commit:
        build_arn = event_details["build-id"]
        build_id = build_arn.split("/")[-1]
        build_uuid = build_id.split(":")[-1]
        source_url = additional_information["source"]["location"]
        repo_name = source_url.split("/")[-1]
        project_name = event_details["project-name"]
        build_status = event_details["build-status"]
        region = event["region"]
        request_token = build_arn + build_status
        safe_build_id = urllib.parse.quote(build_id, safe="~@#$&()*!+=:;,.?/'")
        job_url = (
            f"https://{region}.console.aws.amazon.com/codebuild/home?"
            f"region={region}#/builds/{safe_build_id}/view/new"
        )

        # Construct the base comment on the build status
        build_status_map = {
            "IN_PROGRESS": ("inProgress", "is **IN PROGRESS**. "),
            "SUCCEEDED": ("passing", "**SUCCEEDED**! "),
            "STOPPED": ("failing", "was **CANCELED**. "),
            "TIMED_OUT": ("failing", "**TIMED OUT**. "),
        }

        comment_details = build_status_map.get(
            build_status, ("failing", "**FAILED**. ")
        )

        badge_link = (
            f"![{comment_details[0]}](https://s3.{region}.amazonaws.com/"
            f"codefactory-{region}-prod-default-build-badges/"
            f'{comment_details[0]}.svg "{comment_details[0]}")'
        )

        comment_base = (
            f"Build `{build_uuid}` for project `{project_name}` {comment_details[1]}"
        )

        # Comment is in the form:
        #   '<badge>\n\n<comment_base> <status_msg>'
        comment = f"{badge_link}\n\n{comment_base}"

        comment += (
            f"Visit the [AWS CodeBuild console]({job_url}) to view the build "
            f"details."
        )

        # Add build logs to the comment for failed builds
        logs = additional_information.get("logs", {})
        log_group = logs.get("group-name")
        log_stream = logs.get("stream-name")

        if (
            build_status not in ["IN_PROGRESS", "SUCCEEDED", "STOPPED"]
            and log_group
            and log_stream
        ):
            log_params = {
                "logGroupName": log_group,
                "logStreamName": log_stream,
                "limit": 30,
                "startFromHead": False,
            }

            log.info("Sending request for CloudWatch Log events...")
            log.debug("GetLogEvents params:\n%s", log_params)
            response = cloudwatchlogs.get_log_events(**log_params)
            log.info("CloudWatch Log request succeeded!")
            log.debug("GetLogEvents response:\n%s", response)
            log_messages = [event["message"] for event in response["events"]]
            comment += "\n```\n{"".join(log_messages)}\n```\n"

        pull_request_params = {
            "repositoryName": repo_name,
            "pullRequestId": pull_request_id[0],
            "beforeCommitId": destination_commit[0],
            "afterCommitId": source_commit[0],
            "content": comment,
            "clientRequestToken": request_token,
        }

        log.info("Posting comment:\n%s", comment)
        post_comment(pull_request_params)
    else:
        log.info("Not a pull-request build")


def handle_codecommit_pull_request_event(event):
    """Gather pull request details and start CodeBuild job."""
    params = {
        "projectName": PROJECT_NAME,
        "sourceVersion": event["detail"]["sourceCommit"],
        "environmentVariablesOverride": [
            {
                "name": "FLOW_PULL_REQUEST_ID",
                "value": event["detail"]["pullRequestId"],
                "type": "PLAINTEXT",
            },
            {
                "name": "FLOW_PULL_REQUEST_SRC_COMMIT",
                "value": event["detail"]["sourceCommit"],
                "type": "PLAINTEXT",
            },
            {
                "name": "FLOW_PULL_REQUEST_DST_COMMIT",
                "value": event["detail"]["destinationCommit"],
                "type": "PLAINTEXT",
            },
        ],
    }
    start_build(params)


def handle_codecommit_repository_event(event):
    """Gather repository event details and start CodeBuild job."""
    params = {"projectName": PROJECT_NAME, "sourceVersion": event["detail"]["commitId"]}
    if event["detail"]["referenceType"] == "branch":
        params["environmentVariablesOverride"] = [
            {
                "name": "FLOW_BRANCH",
                "value": event["detail"]["referenceName"],
                "type": "PLAINTEXT",
            }
        ]
    elif event["detail"]["referenceType"] == "tag":
        params["environmentVariablesOverride"] = [
            {
                "name": "FLOW_TAG",
                "value": event["detail"]["referenceName"],
                "type": "PLAINTEXT",
            }
        ]
    start_build(params)


def handle_cloudwatch_schedule_event(event):
    """Gather event details and start CodeBuild job."""
    params = {
        "projectName": PROJECT_NAME,
        "environmentVariablesOverride": [
            {"name": "FLOW_SCHEDULE", "value": event["time"], "type": "PLAINTEXT"}
        ],
    }
    start_build(params)


def review_codebuild_event(event):
    """Determine whether this is a valid CodeBuild review event."""
    try:
        source = event["source"]
        detail_type = event["detail-type"]

        return (
            source == "aws.codebuild" and detail_type == "CodeBuild Build State Change"
        )
    except KeyError as exc:
        log.error("Caught error: %s", exc, exc_info=exc)

    return False


def review_pull_request_event(event):
    """Determine whether this is a valid pull request review event."""
    try:
        source = event["source"]
        detail_type = event["detail-type"]
        event_type = event["detail"]["event"]

        return (
            source == "aws.codecommit"
            and detail_type == "CodeCommit Pull Request State Change"
            and event_type in ["pullRequestCreated", "pullRequestSourceBranchUpdated"]
        )
    except KeyError as exc:
        log.error("Caught error: %s", exc, exc_info=exc)

    return False


def branch_repository_event(event):
    """Determine whether this is a valid repository branch event."""
    try:
        source = event["source"]
        detail_type = event["detail-type"]
        event_type = event["detail"]["event"]
        reference_type = event["detail"]["referenceType"]

        return (
            source == "aws.codecommit"
            and detail_type == "CodeCommit Repository State Change"
            and event_type == "referenceUpdated"
            and reference_type == "branch"
        )
    except KeyError as exc:
        log.error("Caught error: %s", exc, exc_info=exc)

    return False


def tag_repository_event(event):
    """Determine whether this is a valid repository tag event."""
    try:
        source = event["source"]
        detail_type = event["detail-type"]
        event_type = event["detail"]["event"]
        reference_type = event["detail"]["referenceType"]

        return (
            source == "aws.codecommit"
            and detail_type == "CodeCommit Repository State Change"
            and event_type in ["referenceCreated", " referenceUpdated"]
            and reference_type == "tag"
        )
    except KeyError as exc:
        log.error("Caught error: %s", exc, exc_info=exc)

    return False


def schedule_cloudwatch_event(event):
    """Determine whether this is a valid CloudWatch scheduled event."""
    try:
        source = event["source"]
        detail_type = event["detail-type"]

        return source == "aws.events" and detail_type == "Scheduled Event"
    except KeyError as exc:
        log.error("Caught error: %s", exc, exc_info=exc)

    return False


def review_handler(event, context):  # pylint: disable=unused-argument
    """Entry point for the lambda "review" handler."""
    try:
        log.info("Received event:\n%s", dump_json(event))

        if review_codebuild_event(event):
            log.info("Handling valid CodeBuild review event...")
            handle_codebuild_review_event(event)
        elif review_pull_request_event(event):
            log.info("Handling valid pull request review event...")
            handle_codecommit_pull_request_event(event)
        else:
            log.info("Not a reviewable pull request or CodeBuild event")
    except Exception as exc:
        log.critical("Caught error: %s", exc, exc_info=exc)
        raise


def branch_handler(event, context):  # pylint: disable=unused-argument
    """Entry point for the lambda "branch" handler."""
    try:
        log.info("Received event:\n%s", dump_json(event))

        if branch_repository_event(event):
            log.info("Handling valid CodeCommit branch event...")
            handle_codecommit_repository_event(event)
        else:
            log.info("Not a CodeCommit branch event")
    except Exception as exc:
        log.critical("Caught error: %s", exc, exc_info=exc)
        raise


def tag_handler(event, context):  # pylint: disable=unused-argument
    """Entry point for the lambda "tag" handler."""
    try:
        log.info("Received event:\n%s", dump_json(event))

        if tag_repository_event(event):
            log.info("Handling valid CodeCommit tag event...")
            handle_codecommit_repository_event(event)
        else:
            log.info("Not a CodeCommit tag event")
    except Exception as exc:
        log.critical("Caught error: %s", exc, exc_info=exc)
        raise


def schedule_handler(event, context):  # pylint: disable=unused-argument
    """Entry point for the lambda "schedule" handler."""
    try:
        log.info("Received event:\n%s", dump_json(event))

        if schedule_cloudwatch_event(event):
            log.info("Handling valid CloudWatch schedule event...")
            handle_cloudwatch_schedule_event(event)
        else:
            log.info("Not a CloudWatch schedule event")
    except Exception as exc:
        log.critical("Caught error: %s", exc, exc_info=exc)
        raise
