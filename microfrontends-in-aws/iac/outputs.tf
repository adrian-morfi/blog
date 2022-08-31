output "container_bucket" {
  description = "Name of the container bucket."
  value       = aws_s3_bucket.this["container"].bucket
}

output "header_bucket" {
  description = "Name of the header bucket."
  value       = aws_s3_bucket.this["header"].bucket
}

output "album_bucket" {
  description = "Name of the album bucket."
  value       = aws_s3_bucket.this["album"].bucket
}

output "footer_bucket" {
  description = "Name of the footer bucket."
  value       = aws_s3_bucket.this["footer"].bucket
}

output "distribution_id" {
  description = "The identifier for the distribution. For example: EDFDVBD632BHDS5."
  value       = aws_cloudfront_distribution.this.id
}