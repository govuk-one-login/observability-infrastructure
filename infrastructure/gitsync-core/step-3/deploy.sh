#!/bin/bash
# This script queries topic ARNs from event rule stacks deployed in Step-3,
# assigns them to variables and uses them as input parameters to the deploy
# command for the slack integration template.

STACK_NAME=$1
SLACK_CHANNEL_ID=$2
SLACK_WORKSPACE_ID=$3
REGION=eu-west-2

echo "INFO: collecting topic ARN from: eu-west-2"
TOPIC_ARN_EU_WEST_2=$(
  aws cloudformation describe-stacks \
  --region eu-west-2 \
  --stack-name ${STACK_NAME}-Event-Rules \
  --query 'Stacks[0].Outputs[?OutputKey==`BuildNotificationsEventsSnsTopic`].OutputValue' \
  --output text
  )

# --- NEW: CRITICAL SANITY CHECK ---
if [ -z "$TOPIC_ARN_EU_WEST_2" ] || [ "$TOPIC_ARN_EU_WEST_2" == "None" ]; then
    echo "ERROR: Could not find Topic ARN in eu-west-2. Check if ${STACK_NAME}-Event-Rules exists."
    exit 1
fi
echo "INFO: successfully collected topic ARN from eu-west-2: ${TOPIC_ARN_EU_WEST_2}"

# --- NEW: THE "CLEAN LIST" LOGIC ---
# Start with the mandatory EU ARN. ONLY add a comma if a second ARN actually exists.
EVENT_TOPICS_LIST="${TOPIC_ARN_EU_WEST_2}"

if [ ! -z "${TOPIC_ARN_US_EAST_1}" ] && [ "${TOPIC_ARN_US_EAST_1}" != "None" ] && [ "${TOPIC_ARN_US_EAST_1}" != "null" ]; then
    EVENT_TOPICS_LIST="${EVENT_TOPICS_LIST},${TOPIC_ARN_US_EAST_1}"
    echo "INFO: Added US-EAST-1 topic to list."
fi
# ----------------------------------

echo "INFO: deploying slack integration stack"
aws cloudformation deploy \
    --stack-name "${STACK_NAME}-Slack-Integration" \
    --template-file slack-integration.yaml \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --parameter-overrides \
      EventTopicsList="${EVENT_TOPICS_LIST}" \
      SlackChannelId="${SLACK_CHANNEL_ID}" \
      SlackWorkspaceId="${SLACK_WORKSPACE_ID}"

echo "STATUS: Stack deploy complete."
echo "INFO: Scanning stack health."

# healthcheck on deployment
# Poll the status until it reaches a completion or failure state
while true; do
  STATUS=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}-Slack-Integration" \
    --region $REGION \
    --query "Stacks[0].StackStatus" \
    --output text 2>/dev/null)

  if [[ "$STATUS" == "CREATE_COMPLETE" ]] || [[ "$STATUS" == "UPDATE_COMPLETE" ]]; then
    echo "STATUS: Stack deployment succeeded: $STATUS"
    exit 0
  elif [[ "$STATUS" == "CREATE_FAILED" ]] || [[ "$STATUS" == "ROLLBACK_COMPLETE" ]] || [[ "$STATUS" == "ROLLBACK_FAILED" ]]; then
    echo "STATUS: Stack deployment failed: $STATUS"
    echo "Attempting to delete the failed stack..."
    
    aws cloudformation delete-stack \
      --stack-name "${STACK_NAME}-Slack-Integration" \
      --region $REGION

    echo "Stack deletion initiated. Waiting for deletion to complete..."
    aws cloudformation wait stack-delete-complete \
      --stack-name "${STACK_NAME}-Slack-Integration" \
      --region $REGION

    echo "Stack deletion completed."
    exit 1
  elif [[ "$STATUS" == "UPDATE_ROLLBACK_COMPLETE" ]]; then
    echo "STATUS: Stack deployment failed: $STATUS"
    exit 1
  elif [[ "$STATUS" == "" ]]; then
    echo "STATUS: Stack does not exist"
    exit 1
  else
    echo "STATUS: Waiting for stack to complete. Current status: $STATUS"
    sleep 30
  fi
done
