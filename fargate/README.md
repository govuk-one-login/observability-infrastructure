# Integrating Dynatrace with Fargate

Below are the instructions for instrumenting a Fargate container with Dynatrace OneAgent.

It is recommended to modify your Cloudformation template first, so that the environment variables are in place before OneAgent runs; this will ensure traffic is routed to the correct Dynatrace instance.

## Template

Ensure that the task has sufficient IAM permissions to retrieve the secret and decrypt the KMS key. At the time of writing, the resources are:

- `arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables`
- `arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceProductionVariables`
- `arn:aws:kms:eu-west-2:216552277552:key/4bc58ab5-c9bb-4702-a2c3-5d339604a8fe`

Roughly the changes needed to be made to your template are below. This won't cover all circumstances, and we are more than happy to help in those cases.

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
  IsProd:
    !Equals [production, !Ref Environment]

Mappings:
  Constants:
    DynatraceSecretArn: 
      Value: !If
        - IsProd
        - arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables
        - arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceProductionVariables

Resources:
  ...
  TaskDefinition:
    Type: AWS::ECS::TaskDefintion
    Properties:
      ...
      ContainerDefintions:
      - ...
        Secrets:
        - Name: DT_TENANT
          ValueFrom: !FindInMap [ Constants, DynatraceSecretArn, Value ]
        - Name: DT_TENANTTOKEN
          ValueFrom: !FindInMap [ Constants, DynatraceSecretArn, Value ]
        - Name: DT_CONNECTION_POINT
          ValueFrom: !FindInMap [ Constants, DynatraceSecretArn, Value ]
      ...
```

## Building the container

Before running your docker build, you must be logged in to the Dynatrace docker registry.

The details are for this are:

- URL: khw46367.live.dynatrace.com
- Username: khw46367
- Password: Dynatrace PaaS Token

To create a PaaS token, navigate to <https://khw46367.apps.dynatrace.com/ui/apps/dynatrace.classic.tokens/ui/access-tokens/create> and select PaaS Token from the 'Template' dropdown, give it a sane name and create. Store this somewhere safe like GitHub Actions Secrets, or whichever CI tool you use to build your image.

Add the following to the Dockerfile for your image:

```Dockerfile
COPY --from=khw46367.live.dynatrace.com/linux/oneagent-codemodules:<technology> / /
ENV LD_PRELOAD /opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so
```

`<technology>` should be either of `nodejs` or `java` (if this doesn't fit your technology, let us know and we'll add more options!)

If you are using an Alpine base image, use `oneagent-codemodules-musl` instead for the image name.
