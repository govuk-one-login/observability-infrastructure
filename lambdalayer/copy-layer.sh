#!/bin/bash
# Exit immediately if a command exits with a non-zero status or a variable is unset.
set -eu

# --- 1. CONFIGURATION LOADING ---

# Loads the comprehensive list of ALL approved AWS runtime strings from the local file.
RUNTIME_LIST=$(cat ./lambdalayer/runtime_config.json)

# Fetch core configuration secrets
DT_CONFIG_JSON=$(aws secretsmanager get-secret-value --secret-id DynatraceLayersConfig | jq -r ".SecretString | fromjson")
DYNATRACE_PAAS_TOKEN=$(echo "$DT_CONFIG_JSON" | jq -r ".TOKEN")
BUCKET_NAME=$(echo "$DT_CONFIG_JSON" | jq -r ".S3_BUCKET")
SIGNING_PROFILE=$(echo "$DT_CONFIG_JSON" | jq -r ".SIGNING_PROFILE")

DT_SECRETS_NONPROD=$(aws secretsmanager get-secret-value --secret-id DynatraceNonProductionVariables | jq -r ".SecretString | fromjson")
DT_BASE_URL=$(echo "$DT_SECRETS_NONPROD" | jq -r ".DT_CONNECTION_BASE_URL")


# --- 2. Dynatrace Layer ARN Retrieval (API & GOVERNANCE FIX) ---

# Governance Fix: Explicitly request layer from an authorized region (eu-west-2 assumed).
TARGET_REGION="eu-west-2" 

echo "STATUS: Fetching Dynatrace layer ARNs from authorized region: $TARGET_REGION"

# Updated curl URL includes the '&region=$TARGET_REGION' filter to bypass the regional block.
LAYER_DATA=$(curl -sX GET "$DT_BASE_URL/api/v1/deployment/lambda/layer?withCollector=included&region=$TARGET_REGION" \
  -H "accept: application/json; charset=utf-8" \
  -H "Authorization: Api-Token $DYNATRACE_PAAS_TOKEN" | \
  jq -r '
    .arns[] |
    select(.withCollector == "included") |
    (
      .arn + "|" + .techType
    )
  ')

if [ -z "$LAYER_DATA" ]; then
    echo "ERROR: No Dynatrace layers found in $TARGET_REGION or API call failed."
    exit 1
fi

echo "STATUS: Retrieved layer data successfully."


# --- 3. Main Layer Processing Loop ---

echo "$LAYER_DATA" | while IFS='|' read -r SOURCE_ARN RUNTIME
do
    echo "--- PROCESSING LAYER: $RUNTIME ---"
    
    # --- GOVERNANCE CHECK (Validates if generic runtime is in the approved list) ---
    # Check if the approved list contains *at least one* runtime string starting with the generic name (e.g., 'java').
    if ! echo "$RUNTIME_LIST" | jq -e 'map(startswith("'"$RUNTIME"'")) | any' >/dev/null; then
        echo "WARNING: Runtime '$RUNTIME' not found in the approved list. Skipping."
        continue
    fi

    # 3a. Define Variables
    LAYER_NAME="Dynatrace_Layer_${RUNTIME}"
    
    # 3b. Get Layer Download Location 
    LAYER_VERSION_INFO=$(aws lambda get-layer-version-by-arn --arn "$SOURCE_ARN")
    
    LAYER_LOCATION=$(echo "$LAYER_VERSION_INFO" | jq -r '.Content.Location')

    if [ -z "$LAYER_LOCATION" ]; then
        echo "ERROR: Failed to retrieve download location for $RUNTIME. Skipping."
        continue
    fi
    
    # 3c. Download and Upload to S3
    echo "STATUS: Downloading layer and uploading to S3..."
    curl -o /tmp/layer.zip "$LAYER_LOCATION"

    S3_UPLOAD_INFO=$(aws s3api put-object \
        --bucket "$BUCKET_NAME" \
        --key "$LAYER_NAME.zip" \
        --body /tmp/layer.zip)
    
    VERSION=$(echo "$S3_UPLOAD_INFO" | jq .VersionId -r)

    
    # 3d. Sign the Layer (Casing fixed)
    echo "STATUS: Starting signing job..."
    SIGNING_JOB=$(aws signer start-signing-job \
        --source "s3={bucketName=$BUCKET_NAME,key=$LAYER_NAME.zip,version=$VERSION}" \
        --destination "s3={bucketName=$BUCKET_NAME,prefix=signed/$LAYER_NAME}" \
        --profile-name "$SIGNING_PROFILE")

    JOB_ID=$(echo "$SIGNING_JOB" | jq '.jobId' -r)

    echo "STATUS: Waiting for signing job $JOB_ID to complete..."
    aws signer wait successful-signing-job --job-id "$JOB_ID"
    
    SIGNING_JOB_DESC=$(aws signer describe-signing-job --job-id "$JOB_ID")

    SIGNED_KEY=$(echo "$SIGNING_JOB_DESC" | jq -r '.signedObject.s3.key')
    SIGNED_BUCKET=$(echo "$SIGNING_JOB_DESC" | jq -r '.signedObject.s3.bucketName')


    # 3e. Publish the New Layer Version
    echo "STATUS: Publishing layer $LAYER_NAME..."
    
    # CRITICAL: Pass the entire list of approved runtimes ($RUNTIME_LIST) to the AWS command.
    LAYER_VERSION_OUTPUT=$(aws lambda publish-layer-version \
        --layer-name "$LAYER_NAME" \
        --content S3Bucket="$SIGNED_BUCKET",S3Key="$SIGNED_KEY" \
        --compatible-runtimes "$RUNTIME_LIST") 

    VERSION_NUMBER=$(echo "$LAYER_VERSION_OUTPUT" | jq -r '.Version')
    LAYER_VERSION_ARN=$(echo "$LAYER_VERSION_OUTPUT" | jq -r '.LayerVersionArn')

    echo "INFO: New published ARN for $RUNTIME: $LAYER_VERSION_ARN"
    
    # 3f. Add Permissions (Grant organizational access)
    echo "STATUS: Granting layer permissions..."
    aws lambda add-layer-version-permission \
        --layer-name "$LAYER_NAME" \
        --version-number "$VERSION_NUMBER" \
        --statement-id DI_ORG \
        --action lambda:GetLayerVersion \
        --principal '*' \
        --organization-id y-xxxxx > /dev/null

done


# --- 4. Final Cleanup ---

rm -f /tmp/layer.zip 

echo "STATUS: Script finished successfully. New ARNs are available in the Lambda console."
