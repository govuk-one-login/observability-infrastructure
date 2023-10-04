terraform {
  backend "s3" {
    bucket         = ""
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock-table"
  }
}