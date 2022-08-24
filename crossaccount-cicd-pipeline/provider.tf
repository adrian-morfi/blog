# Provider to create resources in Account A
provider "aws" {
  alias  = "account_a"
  region = "eu-west-1"

  assume_role {
    role_arn = "PREVIOUS_CREATED_IAC_ROLE_IN_ACCOUNT_A_ARN"
  }
}


# Provider to create resources in Account B
provider "aws" {
  alias  = "account_b"
  region = "eu-west-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63"
    }
  }
}

locals {
  kms_key_arn = "PREVIOUS_CREATED_KMS_KEY_IN_ACCOUNT_B_ARN"

  default_bus_arn = "arn:aws:events:eu-west-1:${var.account_b}:event-bus/default"
}