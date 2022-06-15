variable "environment" {
  type        = string
  description = "The name of the environment we'd like to launch."
}
variable "private_subnets_count" {
  description = "number of p.subnets to create"
  type        = number
}
variable "public_subnets_count" {
  description = "number of p.subnets to create"
  type        = number
}
variable "availability_zones" {
  type        = list(any)
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