provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}


terraform {
  required_version = ">= 0.14.4"
}
