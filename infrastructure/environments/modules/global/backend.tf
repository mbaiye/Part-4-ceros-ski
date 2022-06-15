terraform {
  required_version = ">= 0.14.4"
  backend "s3" {
    region         = "us-east-1"
    profile        = "default"
    key            = "global/s3/terraform.tfstate"
    bucket         = "terraformstatebucket0485"
    dynamodb_table = "terraformstatebucket0485-locks"
    encrypt        = true
  }
}