variable "environment" {
  type = string
  description = "The name of the environment we'd like to launch."
}

variable "repository_url" {
  type = string
  description = "The url of the ECR repository we'll draw our images from."
}

variable "public_key_path" {
  type = string
  description = "The public key that will be used to allow ssh access to the bastions."
  sensitive = true
}
variable "private_subnets_count" {
    description = "number of p.subnets to create"
    type = number
}
variable "public_subnets_count" {
    description = "number of p.subnets to create"
    type = number
}
variable "availability_zones" {
  type        = list
  description = "List of Availability Zones"
}
variable "aws_credentials_file" {
  type = string
}
variable "aws_profile" {
  type = string
}
variable "aws_region" {
  type = string
}