#! /bin/bash

ENVIRONMENT=${1}
# WORKING_DIR="infrastructure/gitsync-core/step-1/template.yaml,infrastructure/gitsync-core/step-2/notification-rules.yaml,infrastructure/gitsync-core/step-3/slack-integration.yaml"
WORKING_DIR="infrastructure/gitsync-core/$ENVIRONMENT"  # this is incorrect but what is currently set in existing stacks

# dev connection ARN, needs to be paramaterised
CODECONNECTION_ARN="arn:aws:codestar-connections:eu-west-2:975050370687:connection/2a0bb694-3010-421b-a31c-45d9b9fc179e"

aws cloudformation deploy \
    --region eu-west-2 \
    --stack-name gitsync-core-pipeline \
    --template-file "${ENVIRONMENT}/gitsync-core-pipeline.yaml" \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset \
    --parameter-overrides \
        CTEnvironment="${ENVIRONMENT}" \
        WorkingDir="${WORKING_DIR}" \
        ConnectionArn="${CODECONNECTION_ARN}"
