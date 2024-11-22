aws cloudformation deploy --stack-name aws-metric-streams-client --region eu-west-2 --template-file ./empty.yaml
aws cloudformation deploy --stack-name github-action-role --region eu-west-2 --template-file ./empty.yaml
echo "STATUS: Stack deploy complete."
