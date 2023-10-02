locals {
  name = concat(var.name, ["storage"])
  name_string = join("-", local.name)
  kms_read_iam_policy_name = join("-", concat(local.name, ["kms", "read", "iamp"]))
  kms_read_write_iam_policy_name = join("-", concat(local.name, ["kms", "read", "write", "iamp"]))
  s3_read_iam_policy_name = join("-", concat(local.name, ["s3", "read", "iamp"]))
  s3_read_write_iam_policy_name = join("-", concat(local.name, ["s3", "read", "write", "iamp"]))
  bucket_name = join("-", concat(local.name, ["bucket"]))
  tags = merge(var.tags, 
  {
    Name: local.name_string
    Module: "storage"
  })
}