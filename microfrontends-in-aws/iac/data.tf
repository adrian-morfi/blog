# S3 Buckets Resource-Base Policy
data "aws_iam_policy_document" "this" {
  for_each = local.microfrontends

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this[each.key].iam_arn]
    }
    resources = [
      "${aws_s3_bucket.this[each.key].arn}/*"
    ]
  }
}