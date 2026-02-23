#!/usr/bin/env bash

TEMPLATE=./empty.yamlx

if [[ ! -r ${TEMPLATE} ]] ; then
  echo "ERROR: Can't see required template file '${TEMPLATE}' in current directory (${PWD})"
  script_dir="$( realpath ${0%/*} )"
  relative_script_dir="${script_dir#${PWD}}" # Remove the CWD part
  # echo ${relative_script_dir#/}
  # echo ".${relative_script_dir}"
  echo "Maybe you need to 'cd .${relative_script_dir}'"
  exit 1
fi

aws cloudformation deploy --stack-name aws-metric-streams-client --region eu-west-2 --template-file ./empty.yaml
echo "STATUS: Stack deploy complete."
