terraform {
  required_version = ">= 0.14.4"
  backend "s3" {
    region  = "us-east-1"
    profile = "default"
    key     = "original/s3/terraform.tfstate"
    bucket  = "terraformstatebucket0485"
    encrypt = true
  }
}