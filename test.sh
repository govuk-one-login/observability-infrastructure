#!/bin/bash

RELEASE_VERSION=1_273

LAYER_ARNS=$(aws lambda list-layers | jq '.Layers[] | .LayerArn' -r | grep "$RELEASE_VERSION")

echo "Layer ARNs: $LAYER_ARNS"

has_java=false
has_nodejs=false
has_python=false

# Check for each required runtime
for arn in $LAYER_ARNS
do
    RUNTIME=`echo "$arn" | tr '_' '\n' | tail -n 1`
    echo "Runtime: $RUNTIME"
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
    echo "Error: The list of ARNs must include one each for Java, Node.js, and Python."
    exit 1
else
    echo "All required ARNs are present."
fi