#!/bin/bash
set -eu

# Set secrets manager secrets as local environment variables
DYNATRACE_CONFIG=`aws secretsmanager get-secret-value --secret-id DynatraceLayersConfig`
DYNATRACE_PAAS_TOKEN=`echo $DYNATRACE_CONFIG | jq -r ".SecretString | fromjson | .TOKEN"`
BUCKET_NAME=`echo $DYNATRACE_CONFIG| jq -r ".SecretString | fromjson | .S3_BUCKET"`
SIGNING_PROFILE=`echo $DYNATRACE_CONFIG | jq -r ".SecretString | fromjson | .SIGNING_PROFILE"`

if [$ENV = 'nonprod'] || [$ENV = 'test']
then
    DYNATRACE_SECRETS=`aws secretsmanager get-secret-value --secret-id DynatraceNonProductionVariables | jq -r ".SecretString | fromjson"`
elif [$ENV = 'prod']
then
    DYNATRACE_SECRETS=`aws secretsmanager get-secret-value --secret-id DynatraceProductionVariables | jq -r ".SecretString | fromjson"`
elif 
then
    echo ERROR: Failed to specify valid environment in github CI.
    exit 1 # terminate and indicate error
fi

#TEST 1_273_3
# List all the lambda layer names in this AWS account and only select the ones with the correct release version
LAYER_NAMES=`aws lambda list-layers | jq '.Layers[] | .LayerName' -r` | grep $RELEASE_VERSION

#if LAYER_NAMES is empty then error and exit
if [ -z "$LAYER_NAMES" ]    
then
    echo ERROR: Failed to retreve the desired version $RELEASE_VERSION
    exit 1 # terminate and indicate error
fi

# Loop through all lambda layers of release version for NodeJS, Java, python
for LAYER_NAME in $LAYER_NAMES
do
    # get the runtime of the current layer
    RUNTIME=`echo "$LAYER_NAME" | tr '_' '\n' | tail -n 1`

    # get aws layer arns
    LAYER_VERSION_ARN=`aws lambda list-layer-versions-by-layer-name --layer-name $LAYER_NAME | jq '.LayerVersions[0].LayerVersionArn' -r`

    if [ $RUNTIME = 'nodejs' ]
    then
        DYNATRACE_SECRETS=`echo $DYNATRACE_SECRETS | jq ".NODEJS_LAYER = \"$LAYER_VERSION_ARN\""`
    elif [ $RUNTIME = 'java' ]
    then
        DYNATRACE_SECRETS=`echo $DYNATRACE_SECRETS | jq ".JAVA_LAYER = \"$LAYER_VERSION_ARN\""`
    elif [ $RUNTIME = 'python' ]
    then
        DYNATRACE_SECRETS=`echo $DYNATRACE_SECRETS | jq ".PYTHON_LAYER = \"$LAYER_VERSION_ARN\""`
    fi
done

echo Updating the ${ENV} lambda layer version for one agent to version ${RELEASE_VERSION}
echo $DYNATRACE_SECRETS > tmp.json

# Update the secrets manager secret with the new variable
if [$ENV = 'test'] 
    aws secretsmanager create-secret --name DynatraceDevVariables --secret-string file://tmp.json > /dev/null
then
# elif [$ENV = 'nonprod']
# then
#     aws secretsmanager put-secret-value --secret-id DynatraceNonProductionVariables --secret-string file://tmp.json > /dev/null
# elif [$ENV = 'prod']
# then
#     aws secretsmanager put-secret-value --secret-id DynatraceProductionVariables --secret-string file://tmp.json > /dev/null
elif 
then
    echo ERROR: Failed to specify valid environment in github CI.
    exit 1 # terminate and indicate error
fi

rm -f tmp.json