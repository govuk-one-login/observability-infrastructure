#!/bin/bash
set -eu
echo "STATUS: Script starting. The release version is $RELEASE_VERSION and the env is $ENV"
#TEST
# List all the lambda layer arns in this AWS account and only select the ones with the correct release version
echo "STATUS: Fetching layer arns..."

LAYER_ARNS=$(aws lambda list-layers | jq '.Layers[] | .LayerArn' -r | grep "$RELEASE_VERSION")
echo "STATUS: Recovered layer arns. $LAYER_ARNS"

### TESTING LAYER_ARNS

echo "--- Begin Testing---"
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

echo "---Deployment to version $RELEASE_VERSION---"
