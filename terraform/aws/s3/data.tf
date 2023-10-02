data "aws_iam_policy_document" "read_write" {

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]

  }

  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.this.arn,
    ]

  }
}

data "aws_iam_policy_document" "read" {

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]

  }

  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.this.arn,
    ]

  }
}