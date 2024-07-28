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
elif [ "$ENV" = 'prod' ]
then
    DYNATRACE_SECRETS=$(aws secretsmanager get-secret-value --secret-id DynatraceProductionVariables | jq -r ".SecretString | fromjson")
else
    echo "ERROR: Failed to specify valid environment in github CI. Variable is $ENV"
    exit 1 # terminate and indicate error
fi

#TEST 1_273_3
# List all the lambda layer arns in this AWS account and only select the ones with the correct release version
echo "STATUS: Fetching layer names..."

LAYER_ARNS=$(aws lambda list-layers | jq '.Layers[] | .LayerArn' -r | grep "$RELEASE_VERSION")
echo "STATUS: Recovered layer arns. $LAYER_ARNS"
echo "STATUS: Searching for version $RELEASE_VERSION..."

LAYER_ARNS=$(echo "$LAYER_ARNS" | grep "$RELEASE_VERSION")
echo "STATUS: Recovered layer ARNS of version $RELEASE_VERSION"


### TESTING LAYER_ARNS

has_java=false
has_nodejs=false
has_python=false
layer_count=0

# Check that there are exactly three arns
# Check for each required runtime
for arn in $LAYER_ARNS
do
    RUNTIME=`echo "$arn" | tr '_' '\n' | tail -n 1`
    echo "Runtime: $RUNTIME"
    layer_count=$((layer_count+1))

    if [[ "$RUNTIME" == 'java' ]]
    then
        has_java=true
    elif [[ "$RUNTIME" == 'nodejs' ]]
    then
        has_nodejs=true
    elif [[ "$RUNTIME" == 'python' ]]
    then
        has_python=true
    fi
done

# Verify all required runtimes are present
if ! $has_java || ! $has_nodejs || ! $has_python
then
    echo "ERROR: The list of ARNs must include one each for Java, Node.js, and Python."
    exit 1
else
    echo "All required ARNs are present."
fi

# Verify there are exactly three ARNs
echo "Number of layers found: $layer_count"
if [ $layer_count != 3 ]
then
    echo "ERROR: There must be exactly 3 layers. No more or less."
    exit 1
fi

### RELEASE

# Loop through all lambda layer ARNS of release the layer arn for NodeJS, Java, python
for LAYER_ARN in $LAYER_ARNS
do
    # get the runtime of the current layer
    RUNTIME=`echo "$LAYER_ARN" | tr '_' '\n' | tail -n 1`

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
if [$ENV = 'test'] 
    echo "Deploying selected layers to $ENV"
    # aws secretsmanager put-secret-value --secret-id DynatraceDevVariables --secret-string file://tmp.json > /dev/null
    echo "Secret push to DynatraceDevVariables successful"
then
# elif [$ENV = 'nonprod']
# then
#     aws secretsmanager put-secret-value --secret-id DynatraceNonProductionVariables --secret-string file://tmp.json > /dev/null
#     echo "Secret push to DynatraceNonProductionVariables successfull"
# elif [$ENV = 'prod']
# then
#     aws secretsmanager put-secret-value --secret-id DynatraceProductionVariables --secret-string file://tmp.json > /dev/null
#     echo "Secret push to DynatraceProductionVariables successfull"
elif 
then
    echo "ERROR: Failed to specify valid environment in github CI."
    exit 1 # terminate and indicate error
fi

rm -f tmp.json