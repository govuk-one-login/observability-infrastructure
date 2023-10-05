# Integrating Dynatrace with Fargate

Below are the instructions for instrumenting a Fargate container with Dynatrace OneAgent.

It is recommended that you modify your Cloudformation template first so that the environment variables are in place before OneAgent runs; this will make sure traffic is routed to the correct Dynatrace instance.

If you have any issues with the implementation, please refer to the [FAQ](../FAQ.md) first.

## Prerequisites

Ensure you run the latest VPC stack and SAM Deployment Pipeline stack versions. At time of writing, v2.0.8 and v2.37.1, respectively. You can check the version of stacks in the [CloudFormation Console](https://eu-west-2.console.aws.amazon.com/cloudformation/home?region=eu-west-2#/stacks) in the description column.

Your container needs to have access to the internet, so that it can send it's metrics to Dynatrace.

To pull secrets from Secrets Manager, your VPC will need a VPC Endpoint for Secrets Manager.

## Template

Ensure the task has sufficient IAM permissions to retrieve the secret and decrypt the KMS key. At the time of writing, the resources are:

- `arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables`
  - `secretsmanager:GetSecretValue`
- `arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceProductionVariables`
  - `secretsmanager:GetSecretValue`
- `arn:aws:secretsmanager:eu-west-2:216552277552:secret:*`
  - `secretsmanager:ListSecrets`
- `arn:aws:kms:eu-west-2:216552277552:key/*`
  - `kms:Decrypt`

Roughly the changes needed to be made to your template are below. This will only cover some circumstances; we are happy to help.

```yaml
AWSTemplateFormatVersion: 2010-09-09
Transform: AWS::Serverless-2016-10-31
Description: >-
  An example template for Dynatrace Instrumentation.

Environment:
  Description: "The name of the environment to deploy to."
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
  IsProd:
    !Equals [production, !Ref Environment]

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

Resources:
  ...
  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      ...
      ContainerDefintions:
      - ...
        Secrets:
        - Name: DT_TENANT
          ValueFrom: !Join
            - ''
            - - !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
              - ':DT_TENANT::'
        - Name: DT_TENANTTOKEN
          ValueFrom: !Join
            - ''
            - - !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
              - ':DT_TENANTTOKEN::'
        - Name: DT_CONNECTION_POINT
          ValueFrom: !Join
          - ''
          - - !FindInMap [ EnvironmentConfiguration, !Ref Environment, dynatraceSecretArn ]
            - ':DT_CONNECTION_POINT::'
      ...
```

## Building the container

Before running your docker build, you must be logged in to the Dynatrace docker registry.

The details for this are:

- URL: khw46367.live.dynatrace.com
- Username: khw46367
- Password: Dynatrace PaaS Token

```yaml
...
  - name: Login to GDS Dev Dynatrace Container Registry
    uses: docker/login-action@v3
    with:
      registry: khw46367.live.dynatrace.com
      username: khw46367
      password: ${{ secrets.DYNATRACE_PAAS_TOKEN }}
...
```

To create a PaaS token, navigate to <https://khw46367.apps.dynatrace.com/ui/apps/dynatrace.classic.tokens/ui/access-tokens/create> and select PaaS Token from the 'Template' dropdown, give it a sane name and create. You should store this somewhere safe, like GitHub Actions Secrets or whichever CI tool you use to build your image.

Add the following to the Dockerfile for your image:

```Dockerfile
COPY --from=khw46367.live.dynatrace.com/linux/oneagent-codemodules:<technology> / /
ENV LD_PRELOAD /opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so
```

`<technology>` should be either `nodejs` or `java` (if this doesn't fit your technology, let us know, and we'll add more options!)

Using an Alpine base image, use `oneagent-codemodules-musl` instead for the image name.
