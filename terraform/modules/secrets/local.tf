locals {
  name                           = concat(var.name, ["secrets"])
  name_string                    = join("-", local.name)
  kms_read_iam_policy_name       = join("-", concat(local.name, ["kms", "read", "iamp"]))
  kms_read_write_iam_policy_name = join("-", concat(local.name, ["kms", "read", "write", "iamp"]))
  tags = merge(var.tags,
    {
      Name : local.name_string
      Module : "secrets"
  })
}