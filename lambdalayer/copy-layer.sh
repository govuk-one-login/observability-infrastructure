#!/bin/bash
# Exit immediately if a command exits with a non-zero status or a variable is unset.
set -eu

# --- 1. Utility Functions ---

# Function to retrieve a secret value and parse its SecretString into a variable.
# Rationale: Centralizes the AWS CLI call and complex JSON parsing for cleaner code.
get_secret_json() {
    local secret_id="$1"
    local target_var_name="$2"
    
    echo "STATUS: Fetching secret: $secret_id"
    local secret_value
    secret_value=$(aws secretsmanager get-secret-value --secret-id "$secret_id" | jq -r '.SecretString | fromjson')
    
    eval "$target_var_name=\$secret_value"
}


# --- 2. Secret and Configuration Retrieval ---

# Fetch and parse core configuration secrets once
DT_CONFIG_JSON=$(aws secretsmanager get-secret-value --secret-id DynatraceLayersConfig | jq -r ".SecretString | fromjson")

DYNATRACE_PAAS_TOKEN=$(echo "$DT_CONFIG_JSON" | jq -r ".TOKEN")
BUCKET_NAME=$(echo "$DT_CONFIG_JSON" | jq -r ".S3_BUCKET")
SIGNING_PROFILE=$(echo "$DT_CONFIG_JSON" | jq -r ".SIGNING_PROFILE")

# Retrieve and parse environment-specific secrets using the helper function
get_secret_json DynatraceNonProductionVariables DYNATRACE_SECRETS
get_secret_json DynatraceProductionVariables PROD_DYNATRACE_SECRETS

DT_BASE_URL=$(echo "$DYNATRACE_SECRETS" | jq -r ".DT_CONNECTION_BASE_URL")


# --- 3. Dynatrace Layer ARN Retrieval (GOVERNANCE FIX APPLIED) ---

# CRITICAL FIX: Explicitly request layer from an authorized region (eu-west-2 in this case).
TARGET_REGION="eu-west-2" 

echo "STATUS: Fetching Dynatrace layer ARNs from authorized region: $TARGET_REGION"

# Updated curl URL to include the '&region=$TARGET_REGION' query parameter.
# Rationale: Prevents failure from the Organization's Region Opt-out policy (e.g., ap-southeast-3 block).
LAYER_DATA=$(curl -sX GET "$DT_BASE_URL/api/v1/deployment/lambda/layer?withCollector=included&region=$TARGET_REGION" \
  -H "accept: application/json; charset=utf-8" \
  -H "Authorization: Api-Token $DYNATRACE_PAAS_TOKEN" | \
  jq -r '
    .arns[] |
    # Filter for layers that INCLUDE the collector
    select(.withCollector == "included") |
    (
      # NEW OUTPUT FORMAT: FULL_ARN | RUNTIME 
      .arn + "|" + .techType
    )
  ')

if [ -z "$LAYER_DATA" ]; then
    echo "ERROR: No Dynatrace layers found in $TARGET_REGION or API call failed."
    exit 1
fi

echo "STATUS: Retrieved layer data successfully."


# --- 4. Main Layer Processing Loop ---

# Use the pipe delimiter (IFS='|') to safely read the ARN and the runtime suffix
# Rationale: This robust loop ensures the full, clean ARN and runtime are separated correctly.
echo "$LAYER_DATA" | while IFS='|' read -r SOURCE_ARN RUNTIME
do
    echo "--- PROCESSING LAYER: $RUNTIME ---"
    
    # 4a. Define Variables and Clean Up
    LAYER_NAME="Dynatrace_Layer_${RUNTIME}"
    
    # 4b. Get Layer Download Location
    # Use the clean SOURCE_ARN directly.
    LAYER_VERSION_INFO=$(aws lambda get-layer-version-by-arn --arn "$SOURCE_ARN")
    
    LAYER_LOCATION=$(echo "$LAYER_VERSION_INFO" | jq -r '.Content.Location')

    if [ -z "$LAYER_LOCATION" ]; then
        echo "ERROR: Failed to retrieve download location for $RUNTIME."
        continue
    fi
    
    # 4c. Download and Upload to S3 (Unsigned)
    echo "STATUS: Downloading layer and uploading to S3..."
    curl -o /tmp/layer.zip "$LAYER_LOCATION"

    S3_UPLOAD_INFO=$(aws s3api put-object \
        --bucket "$BUCKET_NAME" \
        --key "$LAYER_NAME.zip" \
        --body /tmp/layer.zip)
    
    VERSION=$(echo "$S3_UPLOAD_INFO" | jq -r .VersionId)

    
    # 4d. Sign the Layer
    echo "STATUS: Starting signing job..."
    SIGNING_JOB=$(aws signer start-signing-job \
        --source "S3={bucketName=$BUCKET_NAME,key=$LAYER_NAME.zip,version=$VERSION}" \
        --destination "S3={bucketName=$BUCKET_NAME,prefix=signed/$LAYER_NAME}" \
        --profile-name "$SIGNING_PROFILE")

    JOB_ID=$(echo "$SIGNING_JOB" | jq -r '.jobId')

    echo "STATUS: Waiting for signing job $JOB_ID to complete..."
    aws signer wait successful-signing-job --job-id "$JOB_ID"
    
    SIGNING_JOB_DESC=$(aws signer describe-signing-job --job-id "$JOB_ID")

    SIGNED_KEY=$(echo "$SIGNING_JOB_DESC" | jq -r '.signedObject.s3.key')
    SIGNED_BUCKET=$(echo "$SIGNING_JOB_DESC" | jq -r '.signedObject.s3.bucketName')


    # 4e. Publish the New Layer Version
    echo "STATUS: Publishing layer $LAYER_NAME..."
    LAYER_VERSION_OUTPUT=$(aws lambda publish-layer-version \
        --layer-name "$LAYER_NAME" \
        --content S3Bucket="$SIGNED_BUCKET",S3Key="$SIGNED_KEY" \
        --compatible-runtimes "$RUNTIME") # Added: Ensures the layer is only attached to correct runtimes.

    VERSION_NUMBER=$(echo "$LAYER_VERSION_OUTPUT" | jq -r '.Version')
    LAYER_VERSION_ARN=$(echo "$LAYER_VERSION_OUTPUT" | jq -r '.LayerVersionArn')

    
    # 4f. Add Permissions (Grant organizational access)
    echo "STATUS: Granting layer permissions..."
    aws lambda add-layer-version-permission \
        --layer-name "$LAYER_NAME" \
        --version-number "$VERSION_NUMBER" \
        --statement-id DI_ORG \
        --action lambda:GetLayerVersion \
        --principal '*' \
        --organization-id y-xxxxx > /dev/null


    # 4g. Update Secrets Manager Variables
    echo "STATUS: Updating secrets with new ARN: $LAYER_VERSION_ARN"
    
    # Rationale: Uses jq --arg to safely inject the ARN string into the JSON update without shell breaking errors.
    if [ "$RUNTIME" = 'nodejs' ]; then
        DYNATRACE_SECRETS=$(echo "$DYNATRACE_SECRETS" | jq --arg arn "$LAYER_VERSION_ARN" '.NODEJS_LAYER = $arn')
        PROD_DYNATRACE_SECRETS=$(echo "$PROD_DYNATRACE_SECRETS" | jq --arg arn "$LAYER_VERSION_ARN" '.NODEJS_LAYER = $arn')
    elif [ "$RUNTIME" = 'java' ]; then
        DYNATRACE_SECRETS=$(echo "$DYNATRACE_SECRETS" | jq --arg arn "$LAYER_VERSION_ARN" '.JAVA_LAYER = $arn')
        PROD_DYNATRACE_SECRETS=$(echo "$PROD_DYNATRACE_SECRETS" | jq --arg arn "$LAYER_VERSION_ARN" '.JAVA_LAYER = $arn')
    elif [ "$RUNTIME" = 'python' ]; then
        DYNATRACE_SECRETS=$(echo "$DYNATRACE_SECRETS" | jq --arg arn "$LAYER_VERSION_ARN" '.PYTHON_LAYER = $arn')
        PROD_DYNATRACE_SECRETS=$(echo "$PROD_DYNATRACE_SECRETS" | jq --arg arn "$LAYER_VERSION_ARN" '.PYTHON_LAYER = $arn')
    fi

done


# --- 5. Final Secrets Manager Update (UNCOMMENT TO PUSH CHANGES) ---

echo "--- FINAL SECRETS UPDATE ---"

# Save Non-Production variables
echo "$DYNATRACE_SECRETS" > tmp_nonprod.json
# Rationale: Uses distinct filenames (tmp_nonprod/tmp_prod) to prevent accidental data corruption.
# aws secretsmanager put-secret-value --secret-id DynatraceNonProductionVariables --secret-string file://tmp_nonprod.json > /dev/null
echo "STATUS: Non-Production secret file ready at tmp_nonprod.json (uncomment AWS command to deploy)"


# Save Production variables
echo "$PROD_DYNATRACE_SECRETS" > tmp_prod.json
# aws secretsmanager put-secret-value --secret-id DynatraceProductionVariables --secret-string file://tmp_prod.json > /dev/null
echo "STATUS: Production secret file ready at tmp_prod.json (uncomment AWS command to deploy)"


# --- 6. Cleanup ---
rm -f /tmp/layer.zip tmp_nonprod.json tmp_prod.json

echo "STATUS: Script finished successfully."
