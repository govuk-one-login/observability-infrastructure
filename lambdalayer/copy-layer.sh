#!/bin/bash
set -eu

BUCKET_NAME=${BUCKET_NAME:-di-observability-layers}
SIGNING_PROFILE=${SIGNING_PROFILE:-DynatraceSigner}

LAYER_NAME=$1

LAYER_VERSION=`aws lambda get-layer-version-by-arn --arn arn:aws:lambda:eu-west-2:725887861453:layer:$LAYER_NAME:1`

LAYER_LOCATION=`echo $LAYER_VERSION | jq -r '.Content.Location'`

curl -o /tmp/layer.zip $LAYER_LOCATION

S3=`aws s3api put-object \
  --bucket $BUCKET_NAME \
  --key $LAYER_NAME.zip \
  --body /tmp/layer.zip`
VERSION=`echo $S3 | jq .VersionId -r`

SIGNING_JOB=`aws signer start-signing-job \
  --source "s3={bucketName=$BUCKET_NAME,key=$LAYER_NAME.zip,version=$VERSION}" \
  --destination "s3={bucketName=$BUCKET_NAME,prefix=signed/$LAYER_NAME}" \
  --profile-name $SIGNING_PROFILE`

JOB_ID=`echo $SIGNING_JOB | jq '.jobId' -r`

aws signer wait successful-signing-job --job-id $JOB_ID
SIGNING_JOB=`aws signer describe-signing-job --job-id $JOB_ID`

SIGNED_KEY=`echo $SIGNING_JOB | jq '.signedObject.s3.key' -r`
SIGNED_BUCKET=`echo $SIGNING_JOB | jq '.signedObject.s3.bucketName' -r`

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

echo $LAYER_VERSION | jq '.LayerVersionArn' -r