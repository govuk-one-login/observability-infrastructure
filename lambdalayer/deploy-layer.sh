#!/bin/bash
set -eu
echo "STATUS: Script starting. The release version is $RELEASE_VERSION and the env is $ENV"

# Set secrets manager secrets as local environment variables
DYNATRACE_CONFIG=`aws secretsmanager get-secret-value --secret-id DynatraceLayersConfig`
DYNATRACE_PAAS_TOKEN=`echo $DYNATRACE_CONFIG | jq -r ".SecretString | fromjson | .TOKEN"`
BUCKET_NAME=`echo $DYNATRACE_CONFIG| jq -r ".SecretString | fromjson | .S3_BUCKET"`
SIGNING_PROFILE=`echo $DYNATRACE_CONFIG | jq -r ".SecretString | fromjson | .SIGNING_PROFILE"`

if [ "$ENV" = 'nonprod' ] || [ "$ENV" = 'test' ]
then
    DYNATRACE_SECRETS=$(aws secretsmanager get-secret-value --secret-id DynatraceNonProductionVariables | jq -r ".SecretString | fromjson")
    echo "Secret pull from DynatraceNonProductionVariables successful"
elif [ "$ENV" = 'prod' ]
then
    DYNATRACE_SECRETS=$(aws secretsmanager get-secret-value --secret-id DynatraceProductionVariables | jq -r ".SecretString | fromjson")
    echo "Secret pull to DynatraceProductionVariables successful"
else
    echo "ERROR: Failed to specify valid environment in github CI. Variable is $ENV"
    exit 1 # terminate and indicate error
fi

# List all the lambda layer arns in this AWS account and only select the ones with the correct release version
echo "STATUS: Fetching layer arns..."

LAYER_ARNS=$(aws lambda list-layers | jq '.Layers[] | .LatestMatchingVersion[]' -r | grep "$RELEASE_VERSION")
echo "STATUS: Recovered layer arns."

# RELEASE to secretts manager
echo "---Deployment to version $RELEASE_VERSION---"
echo "--- Begin Release---"

# Loop through all lambda layer ARNS of release the layer arn for NodeJS, Java, python
for LAYER_ARN in $LAYER_ARNS
do
    # get the runtime of the current layer
    RUNTIME=`echo "$LAYER_ARN" | tr '_' '\n' | tail -n 1 | cut -d ':' -f 1`

    if [ $RUNTIME = 'nodejs' ]
    then
        DYNATRACE_SECRETS=`echo $DYNATRACE_SECRETS | jq ".NODEJS_LAYER = \"$LAYER_ARN\""`
    elif [ $RUNTIME = 'java' ]
    then
        DYNATRACE_SECRETS=`echo $DYNATRACE_SECRETS | jq ".JAVA_LAYER = \"$LAYER_ARN\""`
    elif [ $RUNTIME = 'python' ]
    then
        DYNATRACE_SECRETS=`echo $DYNATRACE_SECRETS | jq ".PYTHON_LAYER = \"$LAYER_ARN\""`
    else
        echo "ERROR: Failed to specify valid runtime."
        exit 1 # terminate and indicate error
    fi
done

echo "Updating the ${ENV} lambda layer version for one agent to version ${RELEASE_VERSION}"
echo $DYNATRACE_SECRETS > tmp.json

# Update the secrets manager secret with the new variable
echo "Deploying selected layers to $ENV"
if [ "$ENV" = 'test' ]
then
    aws secretsmanager put-secret-value --secret-id DynatraceDevVariables --secret-string file://tmp.json > /dev/null
    echo "Secret push to DynatraceDevVariables successful"
elif [ "$ENV" = 'nonprod' ]
then
    aws secretsmanager put-secret-value --secret-id DynatraceNonProductionVariables --secret-string file://tmp.json > /dev/null
    echo "Secret push to DynatraceNonProductionVariables successful"
elif [ "$ENV" = 'prod' ]
then
    aws secretsmanager put-secret-value --secret-id DynatraceProductionVariables --secret-string file://tmp.json > /dev/null
    echo "Secret push to DynatraceProductionVariables successful"
else
    echo "ERROR: Failed to specify valid environment in github CI."
    exit 1 # terminate and indicate error
fi

rm -f tmp.json