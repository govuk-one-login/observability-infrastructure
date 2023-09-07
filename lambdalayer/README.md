# Dynatrace Lambda Layer

## Integrating into Cloudformation

### Pipeline changes

If you are using Secure Pipeline to deploy your SAM application, you will need to make the following modifications:

- `AdditionalCodeSigningVersionArns`: add `arn:aws:signer:eu-west-2:216552277552:/signing-profiles/DynatraceSigner/5uwzCCGTPq`
- `CustomKmsKeyArns`: add `arn:aws:kms:eu-west-2:216552277552:key/4bc58ab5-c9bb-4702-a2c3-5d339604a8fe`

### Template

The following is an example of how to integrate the Dynatrace Lambda Layer into your Lambda functions.

This does assume you are using the same runtime for all Lambda functions, if this is not the case, specify the layer per function.

If you are not using Cloudformation, or the following does not satisfy your team's requirements, reach out and we can try to help!

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
        - arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceProductionVariables
        - arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables

Globals:
  Function:
    Environment:
      Variables:
        AWS_LAMBDA_EXEC_WRAPPER: /opt/dynatrace
        DT_CONNECTION_AUTH_TOKEN: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_CONNECTION_AUTH_TOKEN}}'
          - SecretArn: !FindInMap [ Constants, DynatraceSecretArn, Value ]
        DT_CONNECTION_BASE_URL: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_CONNECTION_BASE_URL}}'
          - SecretArn: !FindInMap [ Constants, DynatraceSecretArn, Value ]
        DT_CLUSTER_ID: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_CLUSTER_ID}}'
          - SecretArn: !FindInMap [ Constants, DynatraceSecretArn, Value ]
        DT_LOG_COLLECTION_AUTH_TOKEN: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_LOG_COLLECTION_AUTH_TOKEN}}'
          - SecretArn: !FindInMap [ Constants, DynatraceSecretArn, Value ]
        DT_TENANT: !Sub
          - '{{resolve:secretsmanager:${SecretArn}:SecretString:DT_TENANT}}'
          - SecretArn: !FindInMap [ Constants, DynatraceSecretArn, Value ]
        DT_OPEN_TELEMETRY_ENABLE_INTEGRATION: "true"
    Runtime: java17
    Architectures:
      - x86_64
    # An additional 1.5GB is recommended for Java
    # For Node and Python an additional 500 MB 
    MemorySize: 2048
    CodeSigningConfigArn: !If
      - UseCodeSigning
      - !Ref CodeSigningConfigArn
      - !Ref AWS::NoValue
    Layers: !Sub
      - '{{resolve:secretsmanager:${SecretArn}:SecretString:JAVA_LAYER}}' # or NODEJS_LAYER or PYTHON_LAYER
      - SecretArn: !FindInMap [ Constants, DynatraceSecretArn, Value ]

Resources:
...
```

### Notes

When using Java, ensure that you add an addition 1.5GB headroom of RAM for the layer to run with. This is not necessary with NodeJS.

## Updating the layers

The copy-layer.sh script can be used to automatically download the layer from Dynatrace, sign it and create a new layer.

Call it as, while authenticated as an administrator in the `di-observability-production` AWS account:

```sh
./copy-layer.sh Dynatrace_OneAgent_1_271_112_20230731-073314_with_collector_java
```

it will take a few seconds to finish, and output the layer version ARN at the end.

Update the DynatraceProductionVariables and DynatraceNonProductionVariables secrets in Secret Manager with the new layer ARN.