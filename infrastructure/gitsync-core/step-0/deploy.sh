#!/bin/bash
# This script deploys the core gitsync infrastructure. And regional infrastructure in eu-west-2

STACK_NAME="$1-step-0"
ENVIRONMENT=$2
REGION="eu-west-2"
REPONAME=$3
SECRETNAME=$4

echo "INFO: deploying Secrets Manager stack"
aws cloudformation deploy \
  --region $REGION \
  --stack-name "$STACK_NAME" \
  --template-file template.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    Environment="${ENVIRONMENT}" \
    RepositoryName="${REPONAME}" \
    SecretName="${SECRETNAME}"

echo "STATUS: Stack deploy complete."
echo "INFO: Scanning stack health."

# healthcheck on deployment
# Poll the status until it reaches a completion or failure state
while true; do
  STATUS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
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
      --stack-name "$STACK_NAME" \
      --region $REGION

    echo "Stack deletion initiated. Waiting for deletion to complete..."

    # Wait for the stack deletion to complete
    aws cloudformation wait stack-delete-complete \
      --stack-name "$STACK_NAME" \
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
