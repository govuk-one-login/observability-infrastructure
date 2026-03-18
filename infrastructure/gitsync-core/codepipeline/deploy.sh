#! /bin/bash

ENVIRONMENT=${1}

if [ "$1" != "development" ] && [ "$1" != "non-production" ] && [ "$1" != "production" ];then
  echo " ENVIRONMENT positional parameter required"
  echo " Must be either 'sandbox' or 'non-production' or 'production'"
  echo " Usage: ./deploy.sh ENVIRONMENT"
  exit 1
fi

params_file="./parameters/$ENVIRONMENT.yaml"
if [ -f "${params_file}" ]; then
  echo " [INFO] Loading deployment pipeline parameters from $params_file"
else
  echo " [ERROR] There's no parameters file for $ENVIRONMENT"
  exit 1
fi

# Use yq to get one Key=Value per line
# fetching all params with yq at once gives a cloudformation parameter format error
PARAMS=()
while IFS= read -r line; do
  PARAMS+=("$line")
done < <(yq -r '.parameters | to_entries[] | "\(.key)=\(.value | tostring)"' "$params_file")

CONNECTIONNAME="$(yq '.parameters.ConnectionName' "$params_file")"

echo "INFO: collecting CodeConnection ARN"
CONNECTIONARN=$(
  aws codestar-connections list-connections \
    --query "Connections[?ConnectionName=='${CONNECTIONNAME}'].ConnectionArn" \
    --output text \
    --region eu-west-2)

echo "INFO: Using the CodeConnection: ${CONNECTIONARN}"
PARAMS+=("ConnectionArn=$CONNECTIONARN")

aws cloudformation deploy \
    --region eu-west-2 \
    --stack-name gitsync-core-pipeline \
    --template-file "gitsync-core-pipeline.yaml" \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset \
    --parameter-overrides "${PARAMS[@]}" \
