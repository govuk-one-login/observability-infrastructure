variable "name" {
  description = "Component strings of resource names."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)

  validation {
    condition     = contains(keys(var.tags), "Product")
    error_message = "Tags must contain the Key Product."
  }

  validation {
    condition     = contains(keys(var.tags), "System")
    error_message = "Tags must contain the Key System."
  }

  validation {
    condition     = contains(keys(var.tags), "Environment")
    error_message = "Tags must contain the Key Environment."
  }

  validation {
    condition     = contains(keys(var.tags), "Owner")
    error_message = "Tags must contain the Key Owner."
  }
}

variable "aws_region" {
  description = "The AWS region to use."
  type        = string
  default     = "eu-west-2"

  validation {
    condition     = contains(["af-south-1", "ap-east-1", "ap-northeast-1", "ap-northeast-2", "ap-northeast-3", "ap-southeast-1", "ap-southeast-2", "ap-southeast-3", "ap-southeast-4", "ap-south-1", "ap-south-2", "ca-central-1", "eu-central-1", "eu-central-2", "eu-north-1", "eu-south-1", "eu-south-2", "eu-west-1", "eu-west-2", "eu-west-3", "il-central-1", "me-central-1", "me-south-1", "sa-east-1", "us-east-1", "us-east-2", "us-gov-east-1", "us-gov-west-1", "us-west-1", "us-west-2"], var.aws_region)
    error_message = "The aws region must be one of `af-south-1`, `ap-east-1`, `ap-northeast-1`, `ap-northeast-2`, `ap-northeast-3`, `ap-southeast-1`, `ap-southeast-2`, `ap-southeast-3`, `ap-southeast-4`, `ap-south-1`, `ap-south-2`, `ca-central-1`, `eu-central-1`, `eu-central-2`, `eu-north-1`, `eu-south-1`, `eu-south-2`, `eu-west-1`, `eu-west-2`, `eu-west-3`, `il-central-1`, `me-central-1`, `me-south-1`, `sa-east-1`, `us-east-1`, `us-east-2`, `us-gov-east-1`, `us-gov-west-1`, `us-west-1` or `us-west-2`."
  }
}