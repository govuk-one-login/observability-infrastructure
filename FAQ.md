# FAQ

- **There is a performance degradation after adding the layer**

The Dynatrace layers may require an increase in memory, it is documented for Java, see the Dynatrace [documentation](https://www.dynatrace.com/support/help/shortlink/aws-lambda-extension#lambda-java-rt-mem-limit) here and the notes on the [README](./lambdalayer/README.md#notes). 

- **After adding the layer lambdas are timing out**

Make sure you are using the latest versions of the VPC stack and SAM Deployment Pipeline as per the [Prerequisites](./lambdalayer/README.md#prerequisites). In case we have fallen behind in keeping the versions up to date in the readme you can also check the di-devplatform-deploy repository [tags](https://github.com/alphagov/di-devplatform-deploy/tags) for yourself.

If you are on the latest versions does your lambda function have outbound access to the internet? Is your lambda running in a protected subnet?

To help with debugging consider adding the environment variable `DT_LOGGING_DESTINATION` and setting it to `stdout`