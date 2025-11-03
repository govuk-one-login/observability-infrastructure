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

### Layer ARNs
Due to being on the Enterprise Support plan, the following layer versions are currently supported.

New versions are made available on the 3rd of each month.

| Layer Version  | Layer        | Layer ARNs  	                                                                                                  |
|--------------- |------------- |---------------------------------------------------------------------------------------------------------------- |
| 1.325          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_325_7_20250925-155144_with_collector_nodejs:1  | 
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_325_4_20250923-110827_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_325_39_20251016-084120_with_collector_java:1   |
| 1.323          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_323_2_20250822-051314_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_323_2_20250822-050409_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_323_32_20250917-150137_with_collector_java:1   |
| 1.321          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_321_3_20250725-124102_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_321_2_20250725-050315_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_321_32_20250818-161344_with_collector_java:1   |
| 1.319          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_319_2_20250627-051207_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_319_2_20250627-045358_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_319_42_20250721-173500_with_collector_java:1   |
| 1.317          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_317_2_20250530-044837_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_317_2_20250530-045536_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_317_32_20250618-180601_with_collector_java:1   |
| 1.315          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_315_8_20250521-121435_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_315_4_20250520-085210_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_315_47_20250526-161532_with_collector_java:1   |
| 1.313          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_313_2_20250404-043044_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_313_2_20250404-042729_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_313_36_20250507-184408_with_collector_java:1   |
| 1.311          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_311_2_20250307-045250_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_311_2_20250307-043439_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_311_51_20250331-143707_with_collector_java:1   |
| 1.309          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_309_2_20250207-044931_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_309_2_20250207-043417_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_309_29_20250227-083836_with_collector_java:1   |
| 1.307          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_307_2_20250110-045221_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_307_4_20250113-103753_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_307_43_20250131-143638_with_collector_java:1   |
| 1.305          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_305_2_20241105-141606_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_305_2_20241105-141606_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_305_57_20241206-151704_with_collector_java:1   |
| 1.303          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_303_2_20241004-044259_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_303_2_20241004-043401_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_303_42_20241104-145223_with_collector_java:1   |
| 1.301          | NODEJS_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_301_2_20240906-044428_with_collector_nodejs:1  |
|                | PYTHON_LAYER | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_301_2_20240906-043640_with_collector_python:1  |
|                | JAVA_LAYER   | arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_301_36_20240927-183747_with_collector_java:1   |

For specific information regarding each of the layer versions, please take a look at the [Release Notes](https://docs.dynatrace.com/docs/whats-new/oneagent).

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
      # Please see above, in the Layer ARNs table, for the language specific ARNs and copy it onto the below line
      - arn:aws:lambda:eu-west-2:216552277552:layer:Dynatrace_OneAgent_1_313_36_20250507-184408_with_collector_java:1

Resources:
...
```

## Lambda Layer Deployment

Deployment workflows are triggered based on Git events and corresponding AWS Secrets Manager secrets:

Development: feature/* branch triggers deployment using DynatraceTestVariables secret in the development account.
Non-Production: Merge to main branch triggers deployment using DynatraceNonProductionVariables secret in the production account.
Production: Tag creation (VERSION) triggers deployment using DynatraceProductionVariables secret in the production account.

The desired Dynatrace OneAgent version is specified in /lambdalayer/one-agent-version/VERSION, standardizing the deployed version for all new builds.

### OneAgent Upgrade
Teams should ensure that their lambda layer is always on the latest available, as quickly as possible after it has been released.  The time period that the layer is supported is available next to each layer.

To upgrade existing Lambdas, teams should re-point their applications to use the correct new layer ARN, as specified in the "Currently Supported Layer ARNs" table.
Validation should be done as part of the applications CI testing through to Production.

### Notes

When using Java, please ensure you have a minimum of 1.5GB of RAM for the layer to run with. This is not necessary with NodeJS or Python. Please see the Dynatrace [documentation](https://www.dynatrace.com/support/help/shortlink/aws-lambda-extension#lambda-java-rt-mem-limit).

### Updating the layers

The update-layers workflow runs on a weekly basis and updates the layers, but it can also be executed manually.

## Notes for future

1) Add functionality to deploy only the first 3 layers found. Currently the script deploys all of them even if minor versions are found. 

2) Currently we have one version that upgrades all layers:

java
python
nodeJS

Problem: If there is a problem with one layer, the whole release must be rolled back. 

Solution: Having individual version control for each layer type is a feature that should be looked into in the future. 
