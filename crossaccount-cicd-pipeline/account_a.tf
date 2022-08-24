# CodeCommit Repository in Account A
resource "aws_codecommit_repository" "example_codecommit" {
  repository_name = "testing"
  description     = "Repository in Account A"
  default_branch  = "main"

  provider = aws.account_a
}

# EventBridge Rule in Account A
resource "aws_cloudwatch_event_rule" "event_rule_account_a" {

  name        = "testing-repository-rule"
  description = "Catch push events from main branch of the repository."

  provider = aws.account_a

  event_pattern = jsonencode(
    {
      source      = ["aws.codecommit"],
      detail-type = ["CodeCommit Repository State Change"],
      resources   = [aws_codecommit_repository.example_codecommit.arn],
      detail = {
        event         = ["referenceCreated", "referenceUpdated"],
        referenceType = ["branch"],
        referenceName = ["main"]
      }
    }
  )
}

# EventBridge Rule Target in Account A
resource "aws_cloudwatch_event_target" "event_rule_account_a_target" {
  rule      = aws_cloudwatch_event_rule.event_rule_account_a.name
  target_id = aws_cloudwatch_event_rule.event_rule_account_b.name

  arn = local.default_bus_arn

  role_arn = aws_iam_role.event_rule_account_a_role.arn
  provider = aws.account_a
}



# EventBridge Event Role in Account A
resource "aws_iam_role" "event_rule_account_a_role" {
  name = "testing-repository-event-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ]
  })

  provider = aws.account_a
}



# EventBridge Event Service Policy in Account A
resource "aws_iam_role_policy" "event_rule_account_a_role_permissions" {
  name = "cloudwatch-policy"

  role = aws_iam_role.event_rule_account_a_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:*",
        ]
        Resource = [
          local.default_bus_arn
        ]
      },
    ]
  })

  provider = aws.account_a
}

# Cross Account Role that will be assumed from Account B
resource "aws_iam_role" "crossaccount_role" {
  name = "testing-crossaccount-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::${var.account_b}:root"
        }
      }
    ]
  })

  provider = aws.account_a
}

resource "aws_iam_role_policy" "crossaccount_role_policy" {
  name = "crossaccount-policy"
  role = aws_iam_role.crossaccount_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:*",
        ]
        Resource = [
          aws_codecommit_repository.example_codecommit.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:Decrypt"
        ]
        Resource = [
          # KMS_KEY_ARN
          local.kms_key_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.example_cicd_bucket.arn,
          "${aws_s3_bucket.example_cicd_bucket.arn}/*",
        ]
      },
    ]
  })

  provider = aws.account_a
}