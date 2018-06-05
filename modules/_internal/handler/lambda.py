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
        'critical': logging.CRITICAL,
        'error': logging.ERROR,
        'warning': logging.WARNING,
        'info': logging.INFO,
        'debug': logging.DEBUG
    }
)

# Lambda initializes a root logger that needs to be removed in order to set a
# different logging config
root = logging.getLogger()
if root.handlers:
    for handler in root.handlers:
        root.removeHandler(handler)

logging.basicConfig(
    format='%(asctime)s.%(msecs)03dZ [%(name)s][%(levelname)-5s]: %(message)s',
    datefmt='%Y-%m-%dT%H:%M:%S',
    level=LOG_LEVELS[os.environ.get('LOG_LEVEL', '').lower()])
log = logging.getLogger(__name__)

codebuild = boto3.client('codebuild')
codecommit = boto3.client('codecommit')
cloudwatchlogs = boto3.client('logs')

PROJECT_NAME = os.environ['PROJECT_NAME']


def dump_json(data, indent=2, **opts):
    """Dump JSON output with custom, localized defaults."""
    return json.dumps(data, indent=indent, **opts)


def start_build(params):
    """Start a CodeBuild job."""
    log.info('Sending request to StartBuild...')
    log.debug('StartBuild params:\n%s', params)
    response = codebuild.start_build(**params)
    log.info('StartBuild succeeded!')
    log.debug('StartBuild response:\n%s', response)
    return response


def post_comment(params):
    """Post a comment to a CodeCommit pull request."""
    log.info('Sending request to PostComment...')
    log.debug('PostComment params:\n%s', params)
    response = codecommit.post_comment_for_pull_request(**params)
    log.info('PostComment succeeded!')
    log.debug('PostComment response:\n%s', response)
    return response


def handle_codebuild_review_event(event):
    """Gather build details and post a comment to a managed pull request."""
    event_details = event['detail']
    additional_information = event_details['additional-information']
    environment = additional_information['environment']
    environment_variables = environment['environment-variables']

    pull_request_id = [
        env['value'] for env in environment_variables if
        env['name'] == 'FLOW_PULL_REQUEST_ID'
    ]
    source_commit = [
        env['value'] for env in environment_variables if
        env['name'] == 'FLOW_PULL_REQUEST_SRC_COMMIT'
    ]
    destination_commit = [
        env['value'] for env in environment_variables if
        env['name'] == 'FLOW_PULL_REQUEST_DST_COMMIT'
    ]

    if pull_request_id and source_commit and destination_commit:
        build_arn = event_details['build-id']
        build_id = build_arn.split('/')[-1]
        build_uuid = build_id.split(':')[-1]
        source_url = additional_information['source']['location']
        repo_name = source_url.split('/')[-1]
        project_name = event_details['project-name']
        build_status = event_details['build-status']
        region = event['region']
        request_token = build_arn + build_status

        # Construct the comment based on the build status
        comment = 'Build {} for project {} '.format(build_uuid, project_name)

        build_status_map = {
            'IN_PROGRESS': 'is **in progress**. ',
            'SUCCEEDED': '**succeeded**! ',
            'STOPPED': 'was **canceled**. ',
            'TIMED_OUT': '**timed out**. '
        }

        comment += build_status_map.get(build_status, '**failed**.')

        comment += (
            'Visit the [AWS CodeBuild console](https://{0}.console.aws.amazon.'
            'com/codebuild/home?region={0}#/builds/{1}/view/new) to view the '
            'build details.'.format(
                region,
                urllib.parse.quote(build_id, safe='~@#$&()*!+=:;,.?/\''))
        )

        # Add build logs to the comment for failed builds
        logs = additional_information.get('logs', {})
        log_group = logs.get('group-name')
        log_stream = logs.get('stream-name')

        if (
            build_status not in ['IN_PROGRESS', 'SUCCEEDED', 'STOPPED'] and
            log_group and
            log_stream
        ):
            log_params = {
                'logGroupName': log_group,
                'logStreamName': log_stream,
                'limit': 30,
                'startFromHead': False
            }

            try:
                log.info('Sending request for CloudWatch Log events...')
                log.debug('GetLogEvents params:\n%s', log_params)
                response = cloudwatchlogs.get_log_events(**log_params)
                log.info('CloudWatch Log request succeeded!')
                log.debug('GetLogEvents response:\n%s', response)
                log_messages = [
                    event['message'] for event in response['events']
                ]
                comment += '\n```\n{}\n```\n'.format(''.join(log_messages))
            except Exception as exc:
                log.error('Caught error: %s', exc, exc_info=exc)

        pull_request_params = {
            'repositoryName': repo_name,
            'pullRequestId': pull_request_id[0],
            'beforeCommitId': destination_commit[0],
            'afterCommitId': source_commit[0],
            'content': comment,
            'clientRequestToken': request_token
        }

        log.info('Posting comment:\n%s', comment)
        post_comment(pull_request_params)
    else:
        log.info('Not a pull-request build')


def handle_codecommit_pull_request_event(event):
    """Gather pull request details and start CodeBuild job."""
    params = {
        'projectName': PROJECT_NAME,
        'sourceVersion': event['detail']['sourceCommit'],
        'environmentVariablesOverride': [
            {
                'name': 'FLOW_PULL_REQUEST_ID',
                'value': event['detail']['pullRequestId'],
                'type': 'PLAINTEXT'
            },
            {
                'name': 'FLOW_PULL_REQUEST_SRC_COMMIT',
                'value': event['detail']['sourceCommit'],
                'type': 'PLAINTEXT'
            },
            {
                'name': 'FLOW_PULL_REQUEST_DST_COMMIT',
                'value': event['detail']['destinationCommit'],
                'type': 'PLAINTEXT'
            }
        ]
    }
    start_build(params)


def handle_codecommit_repository_event(event):
    """Gather repository event details and start CodeBuild job."""
    params = {
        'projectName': PROJECT_NAME,
        'sourceVersion': event['detail']['commitId']
    }
    if event['detail']['referenceType'] == 'branch':
        params['environmentVariablesOverride'] = [
            {
                'name': 'FLOW_BRANCH',
                'value': event['detail']['referenceName'],
                'type': 'PLAINTEXT'
            }
        ]
    elif event['detail']['referenceType'] == 'tag':
        params['environmentVariablesOverride'] = [
            {
                'name': 'FLOW_TAG',
                'value': event['detail']['referenceName'],
                'type': 'PLAINTEXT'
            }
        ]
    start_build(params)


def review_codebuild_event(event):
    """Determine whether this is a valid CodeBuild review event."""
    try:
        source = event['source']
        detail_type = event['detail-type']

        return (
            source == 'aws.codebuild' and
            detail_type == 'CodeBuild Build State Change'
        )
    except KeyError as exc:
        log.error('Caught error: %s', exc, exc_info=exc)

    return False


def review_pull_request_event(event):
    """Determine whether this is a valid pull request review event."""
    try:
        source = event['source']
        detail_type = event['detail-type']
        event_type = event['detail']['event']

        return (
            source == 'aws.codecommit' and
            detail_type == 'CodeCommit Pull Request State Change' and
            event_type in [
                'pullRequestCreated', 'pullRequestSourceBranchUpdated'
            ]
        )
    except KeyError as exc:
        log.error('Caught error: %s', exc, exc_info=exc)

    return False


def branch_repository_event(event):
    """Determine whether this is a valid repository branch event."""
    try:
        source = event['source']
        detail_type = event['detail-type']
        event_type = event['detail']['event']
        reference_type = event['detail']['referenceType']

        return (
            source == 'aws.codecommit' and
            detail_type == 'CodeCommit Repository State Change' and
            event_type == 'referenceUpdated' and
            reference_type == 'branch'
        )
    except KeyError as exc:
        log.error('Caught error: %s', exc, exc_info=exc)

    return False


def tag_repository_event(event):
    """Determine whether this is a valid repository tag event."""
    try:
        source = event['source']
        detail_type = event['detail-type']
        event_type = event['detail']['event']
        reference_type = event['detail']['referenceType']

        return (
            source == 'aws.codecommit' and
            detail_type == 'CodeCommit Repository State Change' and
            event_type in ['referenceCreated', ' referenceUpdated'] and
            reference_type == 'tag'
        )
    except KeyError as exc:
        log.error('Caught error: %s', exc, exc_info=exc)

    return False


def review_handler(event, context):
    """Entry point for the lambda "review" handler."""
    try:
        log.info('Received event:\n%s', dump_json(event))

        if review_codebuild_event(event):
            log.info('Handling valid CodeBuild review event...')
            handle_codebuild_review_event(event)
        elif review_pull_request_event(event):
            log.info('Handling valid pull request review event...')
            handle_codecommit_pull_request_event(event)
        else:
            log.info('Not a reviewable pull request or CodeBuild event')
    except Exception as exc:
        log.critical('Caught error: %s', exc, exc_info=exc)
        raise


def branch_handler(event, context):
    """Entry point for the lambda "branch" handler."""
    try:
        log.info('Received event:\n%s', dump_json(event))

        if branch_repository_event(event):
            log.info('Handling valid CodeCommit branch event...')
            handle_codecommit_repository_event(event)
        else:
            log.info('Not a CodeCommit branch event')
    except Exception as exc:
        log.critical('Caught error: %s', exc, exc_info=exc)
        raise


def tag_handler(event, context):
    """Entry point for the lambda "tag" handler."""
    try:
        log.info('Received event:\n%s', dump_json(event))

        if tag_repository_event(event):
            log.info('Handling valid CodeCommit tag event...')
            handle_codecommit_repository_event(event)
        else:
            log.info('Not a CodeCommit tag event')
    except Exception as exc:
        log.critical('Caught error: %s', exc, exc_info=exc)
        raise
