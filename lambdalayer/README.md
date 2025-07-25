# Dynatrace Lambda Layer

Below are the instructions for adding the Dyantrace Layer to a Lambda Function.

If you have any issues with the implementation, please refer to the [FAQ](../FAQ.md) first.

## Versions
Two versions are being maintained, meaning only the following versions of the OneAgent can be deployed.

| Secret ARN 	| Secret Version 	| Includes Layers Version 	| Valid From 	| Valid To 	|
|------------	|----------------	|--------------------	|------------	|----------	|
|  arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables | dab72f93-261a-484e-8578-6d96d5ec71d6                 	|       1_299             	|     September 24       	|     March 25     	|
|  arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceProductionVariables | d1a271d9-191f-4ca5-a149-b0f4e2e99b3a                	|       1_299            	|     September 24       	|     March 25     	|
|  arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables | c92956bd-f2c4-4dff-b832-63e627657c0c                	|       1_311             	|     May 25       	|     November 25     	|
|  arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceProductionVariables | bf8979d1-f9ea-4823-8aaa-b2d0d82abfdb                	|       1_311             	|     May 25       	|     November 25     	|

### Prerequisites

Ensure you run the latest VPC stack and SAM Deployment Pipeline stack versions. At time of writing, v2.2.3 and v2.37.2, respectively. You can check the version of stacks in the [CloudFormation Console](https://eu-west-2.console.aws.amazon.com/cloudformation/home?region=eu-west-2#/stacks) in the description column.

If you are using Secure Pipeline to deploy your SAM application, you will need to make the following modifications:

- `AdditionalCodeSigningVersionArns`: add `arn:aws:signer:eu-west-2:216552277552:/signing-profiles/DynatraceSigner/5uwzCCGTPq`
- `CustomKmsKeyArns`: add `arn:aws:kms:eu-west-2:216552277552:key/4bc58ab5-c9bb-4702-a2c3-5d339604a8fe`

Set `DynatraceApiEnabled` to `Yes` in the VPC Stack's parameters, to allow the Lambda function to call the Dynatrace API.

### Template

The following is an example of integrating the Dynatrace Lambda Layer into your Lambda functions.

This does assume you are using the same runtime for all Lambda functions, if this is not the case, specify the layer per function.

If you are not using Cloudformation or the following does not satisfy your team's requirements, reach out, and we can try to help!

```yaml
AWSTemplateFormatVersion: 2010-09-09
Transform: AWS::Serverless-2016-10-31
Description: >-
  An example template for Dynatrace Instrumentation.

Environment:
  Description: "The name of the environment to deploy to"
  Type: "String"
  Default: dev
  AllowedValues:
  - "dev"
  - "build"
  - "staging"
  - "integration"
  - "production"

Conditions:
  UseCodeSigning:
    !Not [!Equals [none, !Ref CodeSigningConfigArn]]

# Delete where appropriate
Mappings:
  EnvironmentConfiguration:
    dev:
      dynatraceSecretArn: arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables
      dynatraceSecretVersion: c92956bd-f2c4-4dff-b832-63e627657c0c
    build:
      dynatraceSecretArn: arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables
      dynatraceSecretVersion: c92956bd-f2c4-4dff-b832-63e627657c0c
    staging:
      dynatraceSecretArn: arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables
      dynatraceSecretVersion: c92956bd-f2c4-4dff-b832-63e627657c0c
    integration:
      dynatraceSecretArn: arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables
      dynatraceSecretVersion: c92956bd-f2c4-4dff-b832-63e627657c0c
    production:
      dynatraceSecretArn: arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceProductionVariables
      dynatraceSecretVersion: bf8979d1-f9ea-4823-8aaa-b2d0d82abfdb

Globals:
  Function:
    Environment:
      Variables:
        AWS_LAMBDA_EXEC_WRAPPER: /opt/dynatrace
        DT_CONNECTION_AUTH_TOKEN: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_CONNECTION_AUTH_TOKEN::${SecretVersion}}}'
          - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
            SecretVersion: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretVersion ]
        DT_CONNECTION_BASE_URL: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_CONNECTION_BASE_URL::${SecretVersion}}}'
          - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
            SecretVersion: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretVersion ]
        DT_CLUSTER_ID: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_CLUSTER_ID::${SecretVersion}}}'
          - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
            SecretVersion: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretVersion ]
        DT_LOG_COLLECTION_AUTH_TOKEN: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_LOG_COLLECTION_AUTH_TOKEN::${SecretVersion}}}'
          - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
            SecretVersion: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretVersion ]
        DT_TENANT: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_TENANT::${SecretVersion}}}'
          - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
            SecretVersion: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretVersion ]
        DT_OPEN_TELEMETRY_ENABLE_INTEGRATION: "true"
    Runtime: java17
    Architectures:
      - x86_64
    # A minimum 1.5GB is recommended for Java
    MemorySize: 2048
    CodeSigningConfigArn: !If
      - UseCodeSigning
      - !Ref CodeSigningConfigArn
      - !Ref AWS::NoValue
    Layers: 
      - !Sub
        - '{{resolve:secretsmanager:${SecretArn}:SecretString:JAVA_LAYER::${SecretVersion}}}' # or NODEJS_LAYER or PYTHON_LAYER
        - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
          SecretVersion: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretVersion ]

Resources:
...
```

### Notes

When using Java, please ensure you have a minimum of 1.5GB of RAM for the layer to run with. This is not necessary with NodeJS or Python. Please see the Dynatrace [documentation](https://www.dynatrace.com/support/help/shortlink/aws-lambda-extension#lambda-java-rt-mem-limit).

## Updating the layers

The update-layers workflow runs on a weekly basis and updates the layers, but it can also be executed manually.

## Lambda Layer Deployment

Deployment workflows are triggered based on Git events and corresponding AWS Secrets Manager secrets:

Development: feature/* branch triggers deployment using DynatraceTestVariables secret in the development account.
Non-Production: Merge to main branch triggers deployment using DynatraceNonProductionVariables secret in the production account.
Production: Tag creation (VERSION) triggers deployment using DynatraceProductionVariables secret in the production account.

The desired Dynatrace OneAgent version is specified in /lambdalayer/one-agent-version/VERSION, standardizing the deployed version for all new builds.

OneAgent Upgrade: To upgrade existing Lambdas, teams must rebuild their deployments to incorporate the latest LAYER_VERSION_ARN from the updated DynatraceProductionVariables secret.

## Notes for future

1) Add functionality to deploy only the first 3 layers found. Currently the script deploys all of them even if minor versions are found. 

2) Currently we have one version that upgrades all layers:

java
python
nodeJS

Problem: If there is a problem with one layer, the whole release must be rolled back. 

Solution: Having individual version control for each layer type is a feature that should be looked into in the future. 
