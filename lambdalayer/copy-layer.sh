#!/bin/bash
set -eu

DYNATRACE_CONFIG=`aws secretsmanager get-secret-value --secret-id DynatraceLayersConfig`

DYNATRACE_PAAS_TOKEN=`echo $DYNATRACE_CONFIG | jq -r ".SecretString | fromjson | .TOKEN"`
BUCKET_NAME=`echo $DYNATRACE_CONFIG| jq -r ".SecretString | fromjson | .S3_BUCKET"`
SIGNING_PROFILE=`echo $DYNATRACE_CONFIG | jq -r ".SecretString | fromjson | .SIGNING_PROFILE"`
DYNATRACE_SECRETS=`aws secretsmanager get-secret-value --secret-id DynatraceNonProductionVariables | jq -r ".SecretString | fromjson"`
PROD_DYNATRACE_SECRETS=`aws secretsmanager get-secret-value --secret-id DynatraceProductionVariables | jq -r ".SecretString | fromjson"`

DT_BASE_URL=`echo $DYNATRACE_SECRETS | jq -r ".DT_CONNECTION_BASE_URL"`

# Get all of the the names of possible 'with_collector' dyanatrace lambda layers
LAYER_NAMES=`curl -sX GET "$DT_BASE_URL/api/v1/deployment/lambda/layer" -H "accept: application/json; charset=utf-8" -H "Authorization: Api-Token $DYNATRACE_PAAS_TOKEN"  | jq " . | (with_entries( select(.key|contains(\"java_with\"))) | .[] | . + \"_java\" ), (with_entries( select(.key|contains(\"python_with\"))) | .[] | . + \"_python\"), (with_entries( select(.key|contains(\"nodejs_with\"))) | .[]| . + \"_nodejs\") " | tr -d '"'`

for LAYER_NAME in $LAYER_NAMES
    do

    # get the runtime of the current layer
    RUNTIME=`echo "$LAYER_NAME" | tr '_' '\n' | tail -n 1`

    LAYER_VERSION=`aws lambda get-layer-version-by-arn --arn arn:aws:lambda:eu-west-2:725887861453:layer:$LAYER_NAME:1`

    LAYER_LOCATION=`echo $LAYER_VERSION | jq -r '.Content.Location'`

    curl -o /tmp/layer.zip $LAYER_LOCATION

    # push the dynatrace provided layer to GDS S3
    S3=`aws s3api put-object \
    --bucket $BUCKET_NAME \
    --key $LAYER_NAME.zip \
    --body /tmp/layer.zip`
    VERSION=`echo $S3 | jq .VersionId -r`

    # Sign the layer
    SIGNING_JOB=`aws signer start-signing-job \
    --source "s3={bucketName=$BUCKET_NAME,key=$LAYER_NAME.zip,version=$VERSION}" \
    --destination "s3={bucketName=$BUCKET_NAME,prefix=signed/$LAYER_NAME}" \
    --profile-name $SIGNING_PROFILE`

    JOB_ID=`echo $SIGNING_JOB | jq '.jobId' -r`

    aws signer wait successful-signing-job --job-id $JOB_ID
    SIGNING_JOB=`aws signer describe-signing-job --job-id $JOB_ID`

    SIGNED_KEY=`echo $SIGNING_JOB | jq '.signedObject.s3.key' -r`
    SIGNED_BUCKET=`echo $SIGNING_JOB | jq '.signedObject.s3.bucketName' -r`

    # publish the new layer
    LAYER_VERSION=`aws lambda publish-layer-version \
    --layer-name $LAYER_NAME \
    --content S3Bucket=$SIGNED_BUCKET,S3Key=$SIGNED_KEY`

    VERSION_NUMBER=`echo $LAYER_VERSION | jq '.Version' -r`

    aws lambda add-layer-version-permission \
    --layer-name $LAYER_NAME \
    --version-number $VERSION_NUMBER \
    --statement-id DI_ORG \
    --action lambda:GetLayerVersion \
    --principal '*' \
    --organization-id o-dpp53lco28 > /dev/null

    LAYER_VERSION_ARN=`echo $LAYER_VERSION | jq '.LayerVersionArn' -r`

    if [ $RUNTIME = 'nodejs' ]
    then
        DYNATRACE_SECRETS=`echo $DYNATRACE_SECRETS | jq ".NODEJS_LAYER = \"$LAYER_VERSION_ARN\""`
        PROD_DYNATRACE_SECRETS=`echo $PROD_DYNATRACE_SECRETS | jq ".NODEJS_LAYER = \"$LAYER_VERSION_ARN\""`
    elif [ $RUNTIME = 'java' ]
    then
        DYNATRACE_SECRETS=`echo $DYNATRACE_SECRETS | jq ".JAVA_LAYER = \"$LAYER_VERSION_ARN\""`
        PROD_DYNATRACE_SECRETS=`echo $PROD_DYNATRACE_SECRETS | jq ".JAVA_LAYER = \"$LAYER_VERSION_ARN\""`
    elif [ $RUNTIME = 'python' ]
    then
        DYNATRACE_SECRETS=`echo $DYNATRACE_SECRETS | jq ".PYTHON_LAYER = \"$LAYER_VERSION_ARN\""`
        PROD_DYNATRACE_SECRETS=`echo $PROD_DYNATRACE_SECRETS | jq ".PYTHON_LAYER = \"$LAYER_VERSION_ARN\""`
    fi
done

echo $DYNATRACE_SECRETS > tmp.json

# aws secretsmanager put-secret-value --secret-id DynatraceNonProductionVariables --secret-string file://tmp.json > /dev/null

echo $PROD_DYNATRACE_SECRETS > tmp.json
# aws secretsmanager put-secret-value --secret-id DynatraceProductionVariables --secret-string file://tmp.json > /dev/null

rm -f tmp.json
