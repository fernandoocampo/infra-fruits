terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.29.0"
    }
  }
  required_version = ">= 1.2.8"
}

provider "aws" {

  access_key = "test"
  secret_key = "test"
  region     = var.aws_region


  # only required for non virtual hosted-style endpoint use case.
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_force_path_style
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://s3.localhost.localstack.cloud:4566"
    sns      = "http://localhost:4566"
    sqs      = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }
}