#! /bin/bash

ENVIRONMENT=${1:-development}
CONNECTIONNAME=${2:-GDS-GitHub-Connection}

echo "INFO: collecting CodeConnection ARN"
CONNECTIONARN=$(
  aws codestar-connections list-connections \
    --query "Connections[?ConnectionName=='${CONNECTIONNAME}'].ConnectionArn" \
    --output text \
    --region eu-west-2)

echo "INFO: Using the CodeConnection: (${CONNECTIONARN})"

# WORKING_DIR="infrastructure/gitsync-core/step-0/template.yaml, infrastructure/gitsync-core/step-1/template.yaml, infrastructure/gitsync-core/step-2/notification-rules.yaml, infrastructure/gitsync-core/step-3/slack-integration.yaml"
WORKING_DIR="infrastructure/gitsync-core/*/*.yaml"

aws cloudformation deploy \
    --region eu-west-2 \
    --stack-name gitsync-core-pipeline \
    --template-file "${ENVIRONMENT}/gitsync-core-pipeline.yaml" \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset \
    --parameter-overrides \
        CTEnvironment="${ENVIRONMENT}" \
        WorkingDir="${WORKING_DIR}" \
        ConnectionArn="${CONNECTIONARN}"
