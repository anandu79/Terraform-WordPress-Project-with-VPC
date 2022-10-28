variable "instance_type" {}
variable "instance_ami" {}
variable "aws_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "project_vpc_cidr" {}
variable "project_subnets" {}
variable "project_name" {}
variable "project_environment" {}
variable "hosted_zone" {}


locals {
  common_tags = {
    project     = var.project_name,
    environment = var.project_environment
  }
}


variable "frontend-webaccess-ports" {
  description = "port for frontend security groups"
  type        = set(string)
}


