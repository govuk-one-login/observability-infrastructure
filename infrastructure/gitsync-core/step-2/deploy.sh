#!/bin/bash
# This script iterates over the regions array and deploys the notifications-rule
# template per specified region.

STACK_NAME=$1
REGION=$2
REPONAME=$3

echo "INFO: executing cloudformation deploy for region: $region"
aws cloudformation deploy \
  --region $REGION \
  --template-file notification-rules.yaml \
  --stack-name $STACK_NAME-Event-Rules \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    GitHubRepoName=${REPONAME}


echo "STATUS: Stack deploy complete."
echo "INFO: Scanning stack health."

# healthcheck on deployment
# Poll the status until it reaches a completion or failure state

while true; do
  STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME-Event-Rules \
    --region $REGION \
    --query "Stacks[0].StackStatus" \
    --output text)

  if [[ "$STATUS" == "CREATE_COMPLETE" ]] || [[ "$STATUS" == "UPDATE_COMPLETE" ]]; then
    echo "STATUS: Stack deployment succeeded: $STATUS"
    exit 0
  elif [[ "$STATUS" == "CREATE_FAILED" ]] || [[ "$STATUS" == "ROLLBACK_COMPLETE" ]] || [[ "$STATUS" == "ROLLBACK_FAILED" ]]; then
    echo "STATUS: Stack deployment failed: $STATUS"
    echo "Attempting to delete the failed stack..."
    
    aws cloudformation delete-stack \
      --stack-name $STACK_NAME-Event-Rules \
      --region $REGION

    echo "Stack deletion initiated. Waiting for deletion to complete..."

    # Wait for the stack deletion to complete
    aws cloudformation wait stack-delete-complete \
      --stack-name $STACK_NAME-Event-Rules \
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

