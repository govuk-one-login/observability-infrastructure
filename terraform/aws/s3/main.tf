resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.kms_encryption_key_provided ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms.aws_kms_key_this_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_iam_policy" "read" {
  name   = var.s3_read_iam_policy_name
  policy = data.aws_iam_policy_document.read.json
}

resource "aws_iam_policy" "read_write" {
  name   = var.s3_read_write_iam_policy_name
  policy = data.aws_iam_policy_document.read_write.json
}