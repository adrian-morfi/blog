# EventBridge Rule in Account B
resource "aws_cloudwatch_event_rule" "event_rule_account_b" {
  name        = "testing-repository-rule"
  description = "Catch push events from main branch of the repository."

  provider = aws.account_b

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

# EventBridge Rule Target in Account B
resource "aws_cloudwatch_event_target" "event_rule_account_b_target" {
  rule     = aws_cloudwatch_event_rule.event_rule_account_b.name
  provider = aws.account_b

  target_id = aws_codepipeline.example_codepipeline.name

  arn = aws_codepipeline.example_codepipeline.arn

  role_arn = aws_iam_role.event_rule_account_b_role.arn
}

# EventBridge Event Role in Account B
resource "aws_iam_role" "event_rule_account_b_role" {
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

  provider = aws.account_b

}


# EventBridge Event Service Policy in Account B
resource "aws_iam_role_policy" "event_rule_account_b_role_permissions" {
  name = "cloudwatch-policy"
  role = aws_iam_role.event_rule_account_b_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codepipeline:StartPipelineExecution",
        ]
        Resource = [
          aws_codepipeline.example_codepipeline.arn
        ]
      },
    ]
  })

  provider = aws.account_b
}


################################################################################################################################################
################################################################################################################################################
################################################################################################################################################



## CodeBuild Project in Account B
resource "aws_codebuild_project" "example_codebuild" {

  name          = "testing-project"
  description   = "test_codebuild_project"
  build_timeout = "5"

  provider = aws.account_b

  service_role = aws_iam_role.example_codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yaml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.example_codebuild_loggroup.name
    }
  }
}


## CodeBuild Role in Account B
resource "aws_iam_role" "example_codebuild_role" {

  name     = "testing-project-role"
  provider = aws.account_b

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })

}

##############################
## CodeBuild Service Policy ##
##############################
resource "aws_iam_role_policy" "example_codebuild_policy" {
  name     = "codebuild-permissions"
  role     = aws_iam_role.example_codebuild_role.name
  provider = aws.account_b

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:GetServiceBearerToken",
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["${aws_cloudwatch_log_group.example_codebuild_loggroup.arn}*"]
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
          "${aws_s3_bucket.example_cicd_bucket.arn}/*"
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
          "sts:AssumeRole"
        ]
        Resource = [
          aws_iam_role.crossaccount_role.arn
        ]
      }
    ]
  })
}

## CodeBuild CloudWatch Log Group in Account B

resource "aws_cloudwatch_log_group" "example_codebuild_loggroup" {
  name              = "/aws/codebuild/testing-project"
  retention_in_days = 7
  provider          = aws.account_b
}


##########################################################################################################################################################################
##########################################################################################################################################################################
##########################################################################################################################################################################
##########################################################################################################################################################################


# S3 Bucket to store artifacts
resource "aws_s3_bucket" "example_cicd_bucket" {
  bucket        = "testing-cicd-bucket"
  force_destroy = true
  provider      = aws.account_b
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example_cicd_bucket_encryption" {
  bucket   = aws_s3_bucket.example_cicd_bucket.id
  provider = aws.account_b

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "example_cicd_bucket_acl" {
  bucket   = aws_s3_bucket.example_cicd_bucket.id
  acl      = "private"
  provider = aws.account_b
}

resource "aws_s3_bucket_public_access_block" "example_cicd_bucket_access_block" {
  bucket                  = aws_s3_bucket.example_cicd_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true

  provider = aws.account_b
}

# Bucket Policy to allow access from Account A
resource "aws_s3_bucket_policy" "example_cicd_bucket_policy" {
  bucket = aws_s3_bucket.example_cicd_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "Allow_Access_From_Account_A"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # AWS = "arn:aws:iam::${var.account_a}:root"
          AWS = aws_iam_role.crossaccount_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.example_cicd_bucket.arn,
          "${aws_s3_bucket.example_cicd_bucket.arn}/*",
        ]
      },
    ]
  })
  provider = aws.account_b
}


##########################################################################################################################################################################
##########################################################################################################################################################################
##########################################################################################################################################################################
##########################################################################################################################################################################

# CodePipeline Pipeline in Account B
resource "aws_codepipeline" "example_codepipeline" {
  name     = "test-pipeline"
  role_arn = aws_iam_role.example_codepipeline_role.arn

  provider = aws.account_b

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.example_cicd_bucket.bucket

    encryption_key {
      id   = local.kms_key_arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_artifact"]
      role_arn         = aws_iam_role.crossaccount_role.arn
      configuration = {
        RepositoryName       = aws_codecommit_repository.example_codecommit.repository_name,
        BranchName           = "main",
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_artifact"]
      configuration = {
        ProjectName = aws_codebuild_project.example_codebuild.name
      }
    }
  }


}



# CodePipeline Role in Account B
resource "aws_iam_role" "example_codepipeline_role" {
  name = "testing-pipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })

  provider = aws.account_b
}

# CodePipeline Service Policy in Account B
resource "aws_iam_role_policy" "example_codepipeline_policy" {
  name = "codepipeline-policy"
  role = aws_iam_role.example_codepipeline_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "Allow_Access_From_Account_A"
    Statement = [
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
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = [
          aws_codebuild_project.example_codebuild.arn,
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
          "sts:AssumeRole"
        ]
        Resource = [
          aws_iam_role.crossaccount_role.arn
        ]
      }
    ]
  })

  provider = aws.account_b
}