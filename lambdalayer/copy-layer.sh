#!/bin/bash
# Exit immediately if a command exits with a non-zero status or a variable is unset.
set -eu

# --- 1. CONFIGURATION LOADING ---

# Define the minimum supported Dynatrace Agent version.
MIN_AGENT_VERSION=$(cat ./lambdalayer/min_agent_version.txt) 

# Fetch core configuration secrets
DT_CONFIG_JSON_RAW=$(aws secretsmanager get-secret-value --secret-id DynatraceLayersConfig)
DT_CONFIG_JSON=$(echo "$DT_CONFIG_JSON_RAW" | jq -r ".SecretString | fromjson")

# Retrieve values by filtering the single DT_CONFIG_JSON variable
DYNATRACE_PAAS_TOKEN=$(echo "$DT_CONFIG_JSON" | jq -r ".TOKEN")
BUCKET_NAME=$(echo "$DT_CONFIG_JSON" | jq -r ".S3_BUCKET")
SIGNING_PROFILE=$(echo "$DT_CONFIG_JSON" | jq -r ".SIGNING_PROFILE")

DT_SECRETS_NONPROD_RAW=$(aws secretsmanager get-secret-value --secret-id DynatraceNonProductionVariables)
DT_SECRETS_NONPROD=$(echo "$DT_SECRETS_NONPROD_RAW" | jq -r ".SecretString | fromjson")
DT_BASE_URL=$(echo "$DT_SECRETS_NONPROD" | jq -r ".DT_CONNECTION_BASE_URL")


# --- 2. Dynatrace Layer ARN Retrieval (API MIGRATION & VERSION CHECK) ---

# Governance Fix: Explicitly request layer from an authorized region (eu-west-2 assumed).
TARGET_REGION="eu-west-2" 

echo "STATUS: Fetching Dynatrace layers and supported runtimes from $TARGET_REGION"

# CRITICAL: Use the new /api/v1/deployment/lambda/layer endpoint.
API_RESPONSE=$(curl -sX GET "$DT_BASE_URL/api/v1/deployment/lambda/layer?withCollector=included&region=$TARGET_REGION" \
  -H "accept: application/json; charset=utf-8" \
  -H "Authorization: Api-Token $DYNATRACE_PAAS_TOKEN")

if [ -z "$API_RESPONSE" ]; then
    echo "ERROR: API call failed or returned no data from $TARGET_REGION."
    exit 1
fi

# 2a. Load the approved runtimes list (SRE Whitelist) from the local config file.
# We trust the config file uses only lowercase prefixes (e.g., 'java17', 'nodejs20.x').
APPROVED_RUNTIME_LIST=$(cat ./lambdalayer/runtime_config.json)
    
if [ -z "$APPROVED_RUNTIME_LIST" ] || [ "$APPROVED_RUNTIME_LIST" = "[]" ]; then
    echo "ERROR: Approved AWS runtimes list is empty. Please populate runtime_config.json. Exit."
    exit 1
fi

# 2b. Extract the specific ARNs we need to process (filtering by minimum agent version).
LAYER_DATA=$(echo "$API_RESPONSE" | jq -r --arg min_version "$MIN_AGENT_VERSION" '
    .arns[] |
    # CRITICAL: Filters to include only layers that meet the collector and version criteria (extracted from ARN).
    select(.withCollector == "included" and 
           (.arn | match("OneAgent_([0-9]+)_([0-9]+)").string | gsub("_"; ".") ) >= $min_version) |
    (.arn + "|" + .techType)
    ')

if [ -z "$LAYER_DATA" ]; then
    echo "ERROR: No compliant Dynatrace ARNs found (Version >= $MIN_AGENT_VERSION). Check API filters."
    exit 1
fi

echo "INFO: Approved runtimes list (from local config) loaded successfully for publishing."


# --- 3. Main Layer Processing Loop ---

echo "$LAYER_DATA" | while IFS='|' read -r SOURCE_ARN RUNTIME
do
    echo "--- PROCESSING LAYER: $RUNTIME ---"
    
    # CRITICAL FIX: Standardize the API's inconsistent capitalization to lowercase (java, nodejs).
    RUNTIME_LOWER=$(echo "$RUNTIME" | tr '[:upper:]' '[:lower:]')

    # 3a. Define Variables (Extract full descriptive name, retaining architecture)
    VERSION_WITH_ARCH=$(echo "$SOURCE_ARN" | sed 's/^.*layer:\(.*\):[0-9]*$/\1/')
    LAYER_NAME=$(echo "$VERSION_WITH_ARCH" | sed 's/_\(x86\|arm\)$//')
    
    # 3b. FILTER: Create a runtime list specific to the current language (e.g., only pythonx).
    # This ensures the Compatible Runtimes column is clean and specific.
    COMPATIBILITY_LIST=$(echo "$APPROVED_RUNTIME_LIST" | jq -r --arg current_runtime "$RUNTIME_LOWER" '
        .[] | select(startswith($current_runtime))
    ' | jq -R . | jq -cs .)
    
    if [ "$COMPATIBILITY_LIST" = "[]" ]; then
        echo "WARNING: No approved runtimes found for $RUNTIME. Skipping publish."
        continue
    fi


    # 3c. Get Layer Download Location 
    LAYER_VERSION_INFO=$(aws lambda get-layer-version-by-arn --arn "$SOURCE_ARN")
    
    LAYER_LOCATION=$(echo "$LAYER_VERSION_INFO" | jq -r '.Content.Location')

    if [ -z "$LAYER_LOCATION" ]; then
        echo "ERROR: Failed to retrieve download location for $RUNTIME. Skipping."
        continue
    fi
    
    # 3d. Download and Upload to S3
    echo "STATUS: Downloading layer and uploading to S3..."
    curl -o /tmp/layer.zip "$LAYER_LOCATION"

    S3_UPLOAD_INFO=$(aws s3api put-object \
        --bucket "$BUCKET_NAME" \
        --key "$LAYER_NAME.zip" \
        --body /tmp/layer.zip)
    
    VERSION=$(echo "$S3_UPLOAD_INFO" | jq .VersionId -r)

    
    # 3e. Sign the Layer (Casing fixed)
    echo "STATUS: Starting signing job..."
    SIGNING_JOB=$(aws signer start-signing-job \
        --source "s3={bucketName=$BUCKET_NAME,key=$LAYER_NAME.zip,version=$VERSION}" \
        --destination "s3={bucketName=$BUCKET_NAME,prefix=signed/$LAYER_NAME}" \
        --profile-name "$SIGNING_PROFILE")

    JOB_ID=$(echo "$SIGNING_JOB" | jq -r '.jobId')

    echo "STATUS: Waiting for signing job $JOB_ID to complete..."
    aws signer wait successful-signing-job --job-id "$JOB_ID"
    
    SIGNING_JOB_DESC=$(aws signer describe-signing-job --job-id "$JOB_ID")

    SIGNED_KEY=$(echo "$SIGNING_JOB_DESC" | jq -r '.signedObject.s3.key')
    SIGNED_BUCKET=$(echo "$SIGNING_JOB_DESC" | jq -r '.signedObject.s3.bucketName')


    # 3f. Publish the New Layer Version
    echo "STATUS: Publishing layer $LAYER_NAME..."
    
    # CRITICAL: Pass the filtered, specific list (COMPATIBILITY_LIST) to the AWS command.
    LAYER_VERSION_OUTPUT=$(aws lambda publish-layer-version \
        --layer-name "$LAYER_NAME" \
        --content S3Bucket="$SIGNED_BUCKET",S3Key="$SIGNED_KEY" \
        --compatible-runtimes "$COMPATIBILITY_LIST") 

    VERSION_NUMBER=$(echo "$LAYER_VERSION_OUTPUT" | jq -r '.Version')
    LAYER_VERSION_ARN=$(echo "$LAYER_VERSION_OUTPUT" | jq -r '.LayerVersionArn')

    echo "INFO: New published ARN for $RUNTIME: $LAYER_VERSION_ARN"
    
    # 3g. Add Permissions (Grant organizational access)
    echo "STATUS: Granting layer permissions..."
    aws lambda add-layer-version-permission \
        --layer-name "$LAYER_NAME" \
        --version-number "$VERSION_NUMBER" \
        --statement-id DI_ORG \
        --action lambda:GetLayerVersion \
        --principal '*' \
        --organization-id o-dpp53lco28 > /dev/null

done


# --- 4. Final Cleanup ---

rm -f /tmp/layer.zip 

echo "STATUS: Script finished successfully. New ARNs are available in the Lambda console."
