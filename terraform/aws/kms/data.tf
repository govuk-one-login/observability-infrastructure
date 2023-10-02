data "aws_iam_policy_document" "read_write" {

  statement {
    actions = [
      "kms:Decrypt*",
      "kms:ListKeyPolicies",
      "kms:Encrypt",
    ]

    resources = [
      aws_kms_key.this.arn,
    ]

  }
}

data "aws_iam_policy_document" "read" {

  statement {
    actions = [
      "kms:ListKeyPolicies",
      "kms:Decrypt*",
    ]

    resources = [
      aws_kms_key.this.arn,
    ]

  }
}