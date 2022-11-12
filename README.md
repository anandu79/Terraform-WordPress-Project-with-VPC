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

## Create a main.tf file to add the configurations required to create the security group.

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
Create another working directory and create a variables.tf file in it.

```
vim variables.tf
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

> A provider in Terraform is a plugin that enables interaction with an API. Here I'm using AWS provider, so add the below contents in it.

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

In this file we will provide the actual values of the variables.

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

## Create main.tf

```
vim main.tf
```

Ceeate a main.tf file and add the below contents in it.

```
#########################################
# VPC
#########################################

    module "vpc" {
   
    source      = "/var/terraform/modules/vpc/"         #====> Here we have mentioned the module directory where we have added the code to create the VPC.
    vpc_cidr    = var.project_vpc_cidr
    subnets     = var.project_subnets
    project     = var.project_name
    environment = var.project_environment
  }

#########################################
# Bastion security group
#########################################

  module "sg-bastion" {

    source         = "/var/terraform/modules/sgroup/"   #====> Mentioned the module directory where we have added the code to create the security group.
    project        = var.project_name
    environment    = var.project_environment
    sg_name        = "bastion"
    sg_description = "bastion security group"
    sg_vpc         = module.vpc.vpc_id
  }

#########################################
# Bastion security group (production)
#########################################

  resource "aws_security_group_rule" "bastion-production" {

    count             = var.project_environment == "prod" ? 1 : 0
    type              = "ingress"
    from_port         = "22"
    to_port           = "22"
    protocol          = "tcp"
    cidr_blocks       = ["enter your IP address/32"]
    security_group_id = module.sg-bastion.sg_id
  }

#########################################
# Bastion security group (developement)
#########################################

  resource "aws_security_group_rule" "bastion-development" {

    count             = var.project_environment == "dev" ? 1 : 0
    type              = "ingress"
    from_port         = "22"
    to_port           = "22"
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
    security_group_id = module.sg-bastion.sg_id
  }

#########################################
# Frontend security group
#########################################

  module "sg-frontend" {

    source         = "/var/terraform/modules/sgroup"
    project        = var.project_name
    environment    = var.project_environment
    sg_name        = "frontend"
    sg_description = "frontend security group"
    sg_vpc         = module.vpc.vpc_id
  }

#########################################
# Frontend security group rule (web-access)
#########################################

  resource "aws_security_group_rule" "frontend-web-access" {

    for_each          = var.frontend-webaccess-ports
    type              = "ingress"
    from_port         = each.key
    to_port           = each.key
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
    security_group_id = module.sg-frontend.sg_id
  }

#########################################
# Frontend security group rule (remote-access)
#########################################

  resource "aws_security_group_rule" "frontend-remote-access" {

    type                     = "ingress"
    from_port                = "22"
    to_port                  = "22"
    protocol                 = "tcp"
    source_security_group_id = module.sg-bastion.sg_id
    security_group_id        = module.sg-frontend.sg_id

  }

#########################################
# Backend security group
#########################################
    
    module "sg-backend" {
  
    source         = "/var/terraform/modules/sgroup/"
    project        = var.project_name
    environment    = var.project_environment
    sg_name        = "backend"
    sg_description = "backend security group"
    sg_vpc         = module.vpc.vpc_id
  }
 
#########################################
# Backend security group rule for SSH access
#########################################
 
  resource "aws_security_group_rule" "backend-ssh-access" {

    type                     = "ingress"
    from_port                = "22"
    to_port                  = "22"
    protocol                 = "tcp"
    source_security_group_id = module.sg-bastion.sg_id
    security_group_id        = module.sg-backend.sg_id

  }
 
#########################################
# Backend security group rule for DB access
#########################################
 
   resource "aws_security_group_rule" "backend-db-access" {

    type                     = "ingress"
    from_port                = "3306"
    to_port                  = "3306"
    protocol                 = "tcp"
    source_security_group_id = module.sg-frontend.sg_id
    security_group_id        = module.sg-backend.sg_id

  }
  ```
  
## Create MariaDB userdata script

Create a ManriaDB userdata script to install it. The file should be created in the working directory itself.

```
vim mariadb-userdata.tmpl
```

Add the below contents in the file:

```
#!/bin/bash


yum install mariadb-server -y
systemctl start mariadb.service
systemctl enable mariadb.service


mysql -e "UPDATE mysql.user SET Password=PASSWORD('${ROOT_PASSWORD}') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
mysql -e "FLUSH PRIVILEGES;"


mysql -u root -p${ROOT_PASSWORD} -e "create database ${DATABASE_NAME};"
mysql -u root -p${ROOT_PASSWORD} -e "create user '${DATABASE_USER}'@'${DATABASE_HOST}' identified by '${DATABASE_PASSWORD}';"
mysql -u root -p${ROOT_PASSWORD} -e "grant all privileges on ${DATABASE_NAME}.* to '${DATABASE_USER}'@'${DATABASE_HOST}';"
mysql -u root -p${ROOT_PASSWORD} -e "flush privileges;"

systemctl restart mariadb.service
```

Go to main.tf file and add the MySQL contents and MariaDB userdata script in it:

```
vim main.tf
```

```
 ##########################
 # MySql
 #########################

 variable "mysql_root_password" {}
 variable "mysql_extra_username" {}
 variable "mysql_extra_password" {}
 variable "mysql_extra_dbname" {}
 variable "mysql_extra_host" {}

###############################################
# Mariadb-Installation UserData Script
###############################################

data "template_file" "mariadb_installation_userdata" {
template = file("mariadb-userdata.tmpl")
    
 vars = {
      
      ROOT_PASSWORD     = var.mysql_root_password
      DATABASE_NAME     = var.mysql_extra_dbname
      DATABASE_USER     = var.mysql_extra_username
      DATABASE_PASSWORD = var.mysql_extra_password
      DATABASE_HOST     = var.mysql_extra_host
    }
  }
```

Add a code to create Keypair:
  
```  
###############################################
# Key pair creation
###############################################

#create key pair in the name "key" in the project directory.

  resource "aws_key_pair" "mykey" {
  key_name   = "${var.project_name}-${var.project_environment}"
  public_key = file("key.pub")
  tags = {
      Name        = "${var.project_name}-${var.project_environment}",
      project     = var.project_name
      environment = var.project_environment
    }
  }
```

Add the below code to create the Bastion, frontend, and backend instances:

> Among them, WordPress is installed in the frontend instance, the database is installed in the backend instance, and the bastion instance will provide SSH access into the frontend and backend instances from the allowed IP address.

```
###############################################
# Bastion Instance
###############################################


resource "aws_instance" "bastion" {
    
    ami                    = var.instance_ami
    instance_type          = var.instance_type
    subnet_id              = module.vpc.subnet_public2_id
    key_name               = aws_key_pair.mykey.id
    vpc_security_group_ids = [module.sg-bastion.sg_id]
    tags = {
      Name        = "${var.project_name}-${var.project_environment}-bastion",
      project     = var.project_name,
      environment = var.project_environment
    }
  }



###############################################
# Backend Instance
###############################################

  resource "aws_instance" "backend" {
   
    ami                    = var.instance_ami
    instance_type          = var.instance_type
    key_name               = aws_key_pair.mykey.id
    subnet_id              = module.vpc.subnet_private1_id
    vpc_security_group_ids = [module.sg-backend.sg_id]
    user_data              = data.template_file.mariadb_installation_userdata.rendered
    tags = {
      Name        = "${var.project_name}-${var.project_environment}-backend",
      project     = var.project_name,
      environment = var.project_environment
    }
    depends_on = [module.vpc.nat, module.vpc.rt_private, module.vpc.rt_association_private]
  }

###############################################
# Frontend Instance
###############################################

  resource "aws_instance" "frontend" {
     
      ami                    = var.instance_ami
      instance_type          = var.instance_type
      key_name               = aws_key_pair.mykey.id
      subnet_id              =  module.vpc.subnet_public1_id
      vpc_security_group_ids = [ module.sg-frontend.sg_id ]
      user_data              = data.template_file.frontend.rendered
      tags = {
          Name    = "${var.project_name}-${var.project_environment}-frontend",
          project = var.project_name,
          environment     = var.project_environment
        }
        depends_on = [ aws_instance.backend]
    }
```

Next, create a file `userdata.sh` in the working directory and add the below code required for the wordpress installation:

```
vim userdata.sh
```

```
#!/bin/bash
sudo amazon-linux-extras install epel -y
sudo amazon-linux-extras install php7.4 -y
sudo yum install httpd -y
sudo systemctl enable httpd
sudo systemctl restart httpd
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo yum install mysql -y
sudo systemctl restart httpd
sudo cp -r wordpress/* /var/www/html/
sudo chown -R apache:apache /var/www/html/*
sudo systemctl restart httpd
cp -r /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo chown -R apache:apache /var/www/html/wp-config.php
sed -i "s/database_name_here/wordpress/" /var/www/html/wp-config.php
sed -i "s/username_here/wordpress/g" /var/www/html/wp-config.php
sed -i "s/password_here/wordpress/g" /var/www/html/wp-config.php
sed -i "s/localhost/${localaddress}/g" /var/www/html/wp-config.php
sudo systemctl restart httpd
```

Add the below code to create template_file in the main.tf

###### What is a template_file?
> The template_file data source renders a template from a template string, which is usually loaded from an external file.

```
vim main.tf
```

```
 ###############################################
 # Template
 ###############################################


  data "template_file" "frontend" {
  template = file("${path.module}/userdata.sh")
      
      vars = {
        localaddress = "${aws_instance.backend.private_ip}"
      }
    }

```

Create a zone record in main.tf file as shown below:

```
 ###############################################
 # Zone record
 ###############################################


  data "aws_route53_zone" "web" {
      name         = "domain.com"
      private_zone = false
    }
    
  resource "aws_route53_record" "wordpress" {
     
      zone_id = var.hosted_zone
      name    = "Enter your domain name"
      type    = "CNAME"
      ttl     = 5
      records = [aws_instance.frontend.public_dns]
    }
```

## Create output.tf file

Create an output.tf file in the working directory.

```
vim output.tf
```

Add the below contents in it:

```
output "database_instanceprivate_ip" {
  value = aws_instance.backend.private_ip
}
```

## Terraform Validation

> This will check for any errors on the source code

```
terraform validate
```

## Terraform plan

> The terraform plan command provides a preview of the actions that Terraform will take in order to configure resources per the configuration file.

```
terraform plan
```

## Terraform apply

>This will execute the .tf file we have created

```
terraform apply
```

# Conclusion

After execution, we will receive a WordPress installation page when "domain.com" in a browser.

###### Connect with me

:call_me_hand:	Connect with me

https://https://www.linkedin.com/in/anandakrishnan-n-b5a03813b/sharing/share-offsite/?url={url}






