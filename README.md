# Terraform WordPress Project with VPC

Here, I have created a WordPress website using Terraform!

I have created a VPC with 3 public subnets, 3 private subnets, a public and private route table, 1 internet gateway, and one NAT gateway.

I have also launched 3 instances which are: bastion, frontend, and backend instances. Among them, WordPress is installed in the frontend instance, the database is installed in the backend instance, and the bastion instance will provide SSH access into the frontend and backend instances from the allowed IP address.

After applying this code, we will receive a WordPress installation page in our domain :)

# Terraform Insatallation

1. Create an IAM user from your AWS console which should have "Access key - programmatic access", and this user should have "Administrator access" policy attached to it.
2. Download and install terraform in the server. Click [here](https://www.terraform.io/downloads) to download terraform. 

You can install terraform in your server by using the commands provided below.

```
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install terraform
```

3. Create a working directory and a module directory where you can add terraform configuration files. Here, I have created a module directory to add the configuration files required to create the VPC, internet gateway, public and private subnets, elastic IP, NAT gateway, route table for public and private subnets, and their associations. This module directory is located in `/var/terraform/`
There is also an other directory created in the module for adding configurations required for creating the bastion security group. I have named it `sgroup`. This bastion instance is used to provide SSH access to frontend and backend instances.

###### Why do we use modules in Terraform?

> A Terraform module is a collection of standard configuration files in a dedicated directory. Terraform modules encapsulate groups of resources dedicated to one task, reducing the amount of code you have to develop for similar infrastructure components.

## Let us proceed to create the modules required for the VPC and bastion securtity group

## VPC module

Create a file variables.tf to declare variables in `/var/terraform/modules/vpc`

> Please note that terraform files should have .tf extension

```
vim variables.tf
```

Add the variables provided here into the file:

```
variable "vpc_cidr" {}
variable "subnets" {}
variable "project" {
  default = "demo"
}
variable "environment" {
  default = "demo"
}
```

## Create a datasource.tf file

> This datasource.tf file is used to get the details regarding the availability zone.

```
vim datasource.tf
```

Add the contents:

```
data "aws_availability_zones" "az" {
  state = "available"
}
```

## Create main.tf file

> Create a main.tf file where we add configurations required to create VPC and other resources.

```
vim main.tf
```

## VPC creation

```
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}
```

## Internet gateway creation

```
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}
```

## Creation of 3 public subnets

> Here, I am adding the code to create 3 public subnets in one resource code:

```
resource "aws_subnet" "public" {
  count                   = var.subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 0)
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-${var.environment}-public-${1 + count.index}"
  }
}
```

## Creation of 3 private subnets

> Same as public subnets, below is the resource code to create 3 private subnets at once:

```
resource "aws_subnet" "private" {
  count                   = var.subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + var.subnets)
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-${var.environment}-private-${1 + count.index}"
  }
}
```

## Elastic IP for NAT gateway

```
resource "aws_eip" "nat" {
  vpc = true
  tags = {
    Name = "${var.project}-${var.environment}-nat"
  }
}
```

## NAT gateway creation

```
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}
```

## Route table creation for the public subnets

```
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-public"
  }
}
```

## Route table creation for the private subnets

```
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-private"
  }
}
```

## Route table association of public subnets to public route table

```
resource "aws_route_table_association" "public_subnbet" {
  count          = var.subnets
  subnet_id      = aws_subnet.public["${count.index}"].id
  route_table_id = aws_route_table.public.id
}
```

## Route table association of private subnets to private route table

```
resource "aws_route_table_association" "private_subnet" {
  count          = var.subnets
  subnet_id      = aws_subnet.private["${count.index}"].id
  route_table_id = aws_route_table.private.id
}
```

## Create an output.tf file

> Create an output.tf file inside the VPC directory to fetch the output. Add the contents provided below in the output.tf file

```
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_public1_id" {
  value = aws_subnet.public[0].id
}

output "subnet_public2_id" {
  value = aws_subnet.public[1].id
}

output "subnet_public3_id" {
  value = aws_subnet.public[2].id
}

output "subnet_private1_id" {
  value = aws_subnet.private[0].id
}

output "subnet_private2_id" {
  value = aws_subnet.private[1].id
}

output "subnet_private3_id" {
  value = aws_subnet.private[2].id
}

output "subnet_public_ids" {

  value = aws_subnet.public[*].id
}

output "subnet_private_ids" {

  value = aws_subnet.private[*].id
}

output "nat" {
    value = aws_nat_gateway.nat.id
}

output "rt_private" {
    value = aws_route_table.private.id
}

output "rt_association_private" {
    value = aws_route_table_association.private_subnet
}
```

# Security group module

Here, we have to create a module for the bastion security group. Create a directory named `sgroup` under `/var/terraform/modules`.

## Create a variable.tf file to declare the variables required for the security group creation.

```
vim variables.tf
```

Add the below variables to the file:

```
variable "project" {}
variable "environment" {}
variable "sg_name" {}
variable "sg_description" {}
variable "sg_vpc" {}
```

## Create a main.tf file to add the configurations required to create the VPC.

```
vim main.tf
```
```
resource "aws_security_group" "sg" {
  name_prefix = "${var.project}-${var.environment}-${var.sg_name}-"
  description = var.sg_description
  vpc_id      = var.sg_vpc
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.project}-${var.environment}-${var.sg_name}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
```

Now that we have finished creating required modules, we will proceed to create the instances and other resources required for the WordPress website.
Create another directory and create a variables.tf file in it.

```
variables.tf
```

Declare the required variables as shown below:

```
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
```

## Create provider.tf file

```
vim provider.tf
```

> A provider in Terraform is a plugin that enables interaction with an API. Here I'm using AWS provider, so add the below files in it.

```
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  default_tags {
    tags = local.common_tags
  }
}
```

## Create terraform.tfvars

```
vim terraform.tfvars
```

In this file we will provide the actual values of the variables declared in the variables.tf file.

```
instance_type            = "t2.micro"
instance_ami             = "enter your AMI ID"
aws_region               = "ap-south-1"
aws_access_key           = "enter your access key"
aws_secret_key           = "enter your secret key"
project_vpc_cidr         = "172.16.0.0/16"
project_name             = "terraform"
project_environment      = "dev"
project_subnets          = 3
frontend-webaccess-ports = [80, 443]
hosted_zone              = "enter your hosted zone ID"

mysql_root_password  = "mysqlroot123"
mysql_extra_username = "wordpress"
mysql_extra_password = "wordpress"
mysql_extra_dbname   = "wordpress"
mysql_extra_host     = "%"
```



