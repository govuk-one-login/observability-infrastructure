# Terraform

## Run in 'local' environment

To run in a local environment add a file under the terraform directory called `terraform.auto.tfvars` with contents similar to:

```
name = ["di", "<your name>", "observability"]
tags = {
    Product: "GOV.UK Sign In"
    System: "Observability"
    Environment: "<you name maybe?>"
    Owner: "<gds email>"
    Source: "https://github.com/govuk-one-login/observability-infrastructure"
}
aws_region = "eu-west-2"
```

Create a dynamoDB table in your environment called `terraform-state-lock-table` it needs a partition key named `LockID` with type of `String`.

Add a bucket name to the `terraform/site.tf` file:

```
terraform {
  backend "s3" {
    bucket = "<add your bucket name in here please>"
    key    = "terraform.tfstate"
    region = "eu-west-2"
    dynamodb_table = "terraform-state-lock-table"
  }
}
```

***DO NOT COMMIT CHANGES TO*** `terraform/site.tf`

## Development 

If you make any change to the modules please make sure you format and validate them. Using S3 as an example, I have made a change and I want to commit:

```bash
...

cd terraform/aws/s3
terraform init --backend=false
terraform fmt
terraform validate
cd -
git add .
git commit

...
```