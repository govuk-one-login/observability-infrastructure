resource "aws_kms_key" "this" {
  description = "KMS key"
  tags        = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_iam_policy" "read" {
  name        = var.kms_read_iam_policy_name
  path        = "/"
  description = "${var.kms_key_alias} read iam policy"

  policy = data.aws_iam_policy_document.read.json
}

resource "aws_iam_policy" "read_write" {
  name        = var.kms_read_write_iam_policy_name
  path        = "/"
  description = "${var.kms_key_alias} read and write iam policy"

  policy = data.aws_iam_policy_document.read_write.json
}