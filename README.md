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

3. Create a working directory where you can add terraform configuration files. Here, I have created a module directory to add the configuration files required to create the VPC, internet gateway, public and private subnets, elastic IP, NAT gateway, route table for public and private subnets, and their associations. This module directory is located in `/var/terraform/`
There is also an other directory created in the module for adding configurations required for creating the bastion security group. I have named it `sgroup`. This bastion instance is used to provide SSH access to frontend and backend instances.

###### Why do we use modules in Terraform?

>A Terraform module is a collection of standard configuration files in a dedicated directory. Terraform modules encapsulate groups of resources dedicated to one task, reducing the amount of code you have to develop for similar infrastructure components.

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





