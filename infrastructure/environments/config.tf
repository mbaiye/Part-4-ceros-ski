provider "aws" {
  profile = var.aws_profile
  region = var.aws_region
  aws_credentials_file = var.aws_credentials_file
}


terraform {
  required_version = ">= 0.14.4"
}
