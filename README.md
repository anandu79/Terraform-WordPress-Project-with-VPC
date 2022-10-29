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
###### VPC module

Create a file variables.tf to declare variables in `/var/terraform/modules/`
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








