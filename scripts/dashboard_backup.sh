#!/bin/bash

OUTPUT_DIR=$(date +'%Y-%m-%d'_backup_dashboard) # Specify the desired output directory

mkdir -p "$OUTPUT_DIR"

# Get the list of dashboards
response=$(curl -sX GET "https://${ENVIRONMENT}.live.dynatrace.com/api/config/v1/dashboards" -H "accept: application/json; charset=utf-8" -H "Authorization: Api-Token ${API_TOKEN}")

# Extract the dashboard IDs from the response
dashboard_ids=$(echo "$response" | jq -r '.dashboards[].id')

# Loop through the dashboard IDs and retrieve each dashboard
for id in $dashboard_ids; do
  # Get the dashboard by ID
  dashboard_response=$(curl -sX GET "https://${ENVIRONMENT}.live.dynatrace.com/api/config/v1/dashboards/$id" -H "accept: application/json; charset=utf-8" -H "Authorization: Api-Token ${API_TOKEN}")

  # Extract the user and dashboard name
  user=$(echo "$dashboard_response" | jq -r '.dashboardMetadata.owner')
  dashboard_name=$(echo "$dashboard_response" | jq -r '.dashboardMetadata.name')

  # Create the subdirectory for the user if it doesn't exist
  user_dir="${OUTPUT_DIR}/${user}"
  mkdir -p "$user_dir"

  # Save the dashboard JSON to a file
  dashboard_file="${user_dir}/${dashboard_name}.json"
  echo "$dashboard_response" > "$dashboard_file"

  echo "Dashboard '$dashboard_name' for user '$user' saved to: $dashboard_file"
done