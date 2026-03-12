# observability-infrastructure

This infrastructure manages:
- the AWS CloudWatch Metric Stream Clients, which send aggregated Organization-wide metrics to Dynatrace
- an AWS CodePipeline, which deploys the initial CloudFormation Stacks and Git sync configuration needed to deploy and automatically update the Metric Stream Client resources
- AWS CodeBuild jobs used by the CodePipeline, to run simple deployment scripts with environment-specific parameters


## Deployment
Due to Git sync limitations, the CloudFormation Stack must exist before Git sync can be enabled and actual resources deployed from templates. There is therefore a multi-stage process needed to both create the Stack with relevant Git sync config, and sync the Stack from templates within the repo

### Prerequisites
Before starting the deployment, the following account-level configuration must have been completed:
- An AWS CodeConnections CodeConnection has been created and authorised
- AWS Chatbot Slack integration has been configured

### Deploying from scratch
1. Manually deploy the initial, empty Metric Streams Client stack
    ```
    cd infrastructure/gitsync-core/init
    ./deploy.sh
    ```
1. Manually create the CodePipeline
    ```
    cd ../codepipeline/
    ./deploy.sh <environment>
    ```
1. The pipeline will execute automatically first time
    1. After Stage 0, the Dynatrace Secret resource in Secrets Manager will be created, but empty. The value be populated manually
    1. Once done, approve the required approval stages
    1. The subsequent pipeline stages will run, pending appropriate approvals, until complete

## Dynatrace Secrets

The Dynatrace API key and endpoint URL are stored in a Secrets Manager Secret resource. This should be an unqualified secret name (no environment prefix), and should be in the format:

Secret name: `DynatraceSecretsV2`
```json
{
    "DYNATRACE_API_KEY": "value",
    "DYNATRACE_ENVIRONMENT_URL": "value"
}
```

## Updating

### Metric Stream Client changes
1. Make relevant changes in the `infrastructure/<env>/aws-metric-streams-client/template.yaml` or `gitsync.yaml` files
1. Commit and open a PR
1. Review the Git sync proposed changes in the PR comments
1. Once merged, the changes will be automatically applied by Git sync


### Git sync configuration changes

1. Make relevant changes in the `infrastructure/gitsync-core/step-[0,1,2,3]` templates or deployment scripts
1. Commit and open a PR
1. Once merged, changes will be automatically applied by CodePipeline


### CodePipeline changes

1. Make relevant changes to the `infrastructure/gitsync-core/codepipeline/<env>/gitsync-core-pipeline.yaml`, starting with `development`
1. Apply the changes locally using the deployment script at `infrastructure/gitsync-core/codepipeline/deploy.sh`
1. Test run the pipeline by triggering manually and validating successful completion
1. Commit the changes and open a PR stating intention to also update the higher environments `non-production` and `production`
1. Once approved, apply same changes


## Known issues

### Dynatrace Secrets resources used by Metric Stream Firehose

Recreating infrastructure from scratch fails because there is a timing issue with the resources in the aws-metric-stream-client template. The Dynatrace secret is created in Secrets Manager, but initially it does not have a value. In the same template, the Metric Streams is also created, but this depends on the Secret having a value.