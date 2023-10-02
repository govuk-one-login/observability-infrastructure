module "kms" {
    source = "../../aws/kms"
    
    aws_region = var.aws_region
    kms_key_alias = local.name_string
    kms_read_iam_policy_name = local.kms_read_iam_policy_name
    kms_read_write_iam_policy_name = local.kms_read_write_iam_policy_name
    tags = local.tags
}

module "s3" {
    source = "../../aws/s3"

    aws_region = var.aws_region
    bucket_name = local.bucket_name
    tags = local.tags
    kms = module.kms
    s3_read_iam_policy_name = local.s3_read_iam_policy_name
    s3_read_write_iam_policy_name = local.s3_read_write_iam_policy_name

}