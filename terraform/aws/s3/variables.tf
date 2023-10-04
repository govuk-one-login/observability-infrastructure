variable "aws_region" {
  description = "The AWS region to use."
  type        = string
  default     = "eu-west-2"

  validation {
    condition     = contains(["af-south-1", "ap-east-1", "ap-northeast-1", "ap-northeast-2", "ap-northeast-3", "ap-southeast-1", "ap-southeast-2", "ap-southeast-3", "ap-southeast-4", "ap-south-1", "ap-south-2", "ca-central-1", "eu-central-1", "eu-central-2", "eu-north-1", "eu-south-1", "eu-south-2", "eu-west-1", "eu-west-2", "eu-west-3", "il-central-1", "me-central-1", "me-south-1", "sa-east-1", "us-east-1", "us-east-2", "us-gov-east-1", "us-gov-west-1", "us-west-1", "us-west-2"], var.aws_region)
    error_message = "The aws region must be one of `af-south-1`, `ap-east-1`, `ap-northeast-1`, `ap-northeast-2`, `ap-northeast-3`, `ap-southeast-1`, `ap-southeast-2`, `ap-southeast-3`, `ap-southeast-4`, `ap-south-1`, `ap-south-2`, `ca-central-1`, `eu-central-1`, `eu-central-2`, `eu-north-1`, `eu-south-1`, `eu-south-2`, `eu-west-1`, `eu-west-2`, `eu-west-3`, `il-central-1`, `me-central-1`, `me-south-1`, `sa-east-1`, `us-east-1`, `us-east-2`, `us-gov-east-1`, `us-gov-west-1`, `us-west-1` or `us-west-2`."
  }
}

variable "bucket_name" {
  description = "The name of the bucket."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-z\\-\\.]+$", var.bucket_name))
    error_message = "The S3 Bucket Name can consist only of lowercase letters, numbers, dots (.), and hyphens (-)."
  }

  validation {
    condition     = length(var.bucket_name) > 2 && length(var.bucket_name) < 64
    error_message = "The Bucket name must be between 3 (min) and 63 (max) characters long."
  }
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

variable "enable_versioning" {
  description = "Should versioning be enabled."
  type        = bool
  default     = true
}

variable "kms_encryption_key_provided" {
  description = "KMS key for encryption will be provided, see var.kms.aws_kms_key_this_arn"
  type        = bool
  default     = true
}

variable "kms" {
  description = "The outputs from the KMS module."
  type = object({
    aws_kms_key_this_arn = string
  })
  default = null
}

variable "s3_read_iam_policy_name" {
  description = "The name of the S3 bucket read IAM policy."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-Za-z\\-\\_\\@\\.\\,\\=\\+]+$", var.s3_read_iam_policy_name))
    error_message = "The S3 Read IAM Policy Name must be alphanumeric, including the following common characters: plus (+), equal (=), comma (,), period (.), at (@), underscore (_), and hyphen (-)."
  }
}

variable "s3_read_write_iam_policy_name" {
  description = "The name of the S3 read and write IAM policy."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-Za-z\\-\\_\\@\\.\\,\\=\\+]+$", var.s3_read_write_iam_policy_name))
    error_message = "The S3 Read and Write IAM Policy Name must be alphanumeric, including the following common characters: plus (+), equal (=), comma (,), period (.), at (@), underscore (_), and hyphen (-)."
  }
}