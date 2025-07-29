# Dynatrace Lambda Layer

Below are the instructions for adding the Dyantrace Layer to a Lambda Function.

If you have any issues with the implementation, please refer to the [FAQ](../FAQ.md) first.

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

### Configuration Values

| Configuration 	                      | NonProd Value 	                     | Prod Value 	                        |
|-------------------------------------- |------------------------------------- |-------------------------------------	|
| DT_CONNECTION_BASE_URL                | https://khw46367.live.dynatrace.com  | https://bhe21058.live.dynatrace.com  |
| DT_CLUSTER_ID                         | -1480073609               	         | -1480073609                   	      |
| DT_TENANT                             | khw46367               	             | bhe21058                   	        |
| DT_OPEN_TELEMETRY_ENABLE_INTEGRATION  | true               	                 | true                   	            |

### Currently Supported Layer ARNs

| Layer 	      | NonProd ARN 	                                                                                                 | Prod ARN 	                                                                                                    |
|---------------|--------------------------------------------------------------------------------------------------------------- |--------------------------------------------------------------------------------------------------------------- |
| NODEJS_LAYER  | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_311_2_20250307-045250_with_collector_nodejs:1 | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_311_2_20250307-045250_with_collector_nodejs:1 |
| JAVA_LAYER    | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_311_51_20250331-143707_with_collector_java:1  | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_311_51_20250331-143707_with_collector_java:1  |
| PYTHON_LAYER  | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_311_2_20250307-043439_with_collector_python:1 | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_311_2_20250307-043439_with_collector_python:1 |


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

Mappings:
  EnvironmentConfiguration:
    dev:
      dynatraceSecretArn: arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables
    build:
      dynatraceSecretArn: arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables
    staging:
      dynatraceSecretArn: arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables
    integration:
      dynatraceSecretArn: arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables
    production:
      dynatraceSecretArn: arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceProductionVariables

Globals:
  Function:
    Environment:
      Variables:
        AWS_LAMBDA_EXEC_WRAPPER: /opt/dynatrace
        DT_CONNECTION_AUTH_TOKEN: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_CONNECTION_AUTH_TOKEN}}'
          - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
        DT_CONNECTION_BASE_URL: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_CONNECTION_BASE_URL}}'
          - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
        DT_CLUSTER_ID: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_CLUSTER_ID}}'
          - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
        DT_LOG_COLLECTION_AUTH_TOKEN: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_LOG_COLLECTION_AUTH_TOKEN}}'
          - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
        DT_TENANT: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_TENANT}}'
          - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
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
        - '{{resolve:secretsmanager:${SecretArn}:SecretString:JAVA_LAYER}}' # or NODEJS_LAYER or PYTHON_LAYER
        - SecretArn: !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]

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
