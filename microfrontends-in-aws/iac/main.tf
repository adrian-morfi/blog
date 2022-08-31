resource "random_id" "this" {
  byte_length = 5
}

resource "aws_s3_bucket_acl" "this" {
  for_each = local.microfrontends

  bucket = aws_s3_bucket.this[each.key].id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = local.microfrontends

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "this" {
  for_each = local.microfrontends

  force_destroy = true
  bucket = "testing-microfrontends-${each.key}-${random_id.this.dec}"
}

resource "aws_s3_bucket_policy" "this" {
  for_each = local.microfrontends

  bucket = aws_s3_bucket.this[each.key].id
  policy = data.aws_iam_policy_document.this[each.key].json
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = local.microfrontends

  bucket = aws_s3_bucket.this[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_cloudfront_origin_access_identity" "this" {
  for_each = local.microfrontends

  comment = "Origin access identity (${each.key})"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "this" {

  price_class         = "PriceClass_100"
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  custom_error_response {
    error_caching_min_ttl = 3600
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 3600
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  origin {
    domain_name = aws_s3_bucket.this["container"].bucket_regional_domain_name
    origin_id   = aws_cloudfront_origin_access_identity.this["container"].id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this["container"].cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_cloudfront_origin_access_identity.this["container"].id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  dynamic "origin" {
    for_each = setsubtract(local.microfrontends, ["container"])

    content {
      domain_name = aws_s3_bucket.this[origin.key].bucket_regional_domain_name
      origin_id   = aws_cloudfront_origin_access_identity.this[origin.key].id

      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.this[origin.key].cloudfront_access_identity_path
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = setsubtract(local.microfrontends, ["container"])

    content {
      path_pattern     = "/${ordered_cache_behavior.key}/*"
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]
      target_origin_id = aws_cloudfront_origin_access_identity.this[ordered_cache_behavior.key].id

      forwarded_values {
        query_string = false

        cookies {
          forward = "none"
        }
      }

      min_ttl                = 0
      default_ttl            = 3600
      max_ttl                = 86400
      viewer_protocol_policy = "redirect-to-https"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
