#########################################
# VPC
#########################################


module "vpc" {
    source      = "/var/terraform/modules/vpc/"
    vpc_cidr    = var.project_vpc_cidr
    subnets     = var.project_subnets
    project     = var.project_name
    environment = var.project_environment
  }

  #########################################
  # Bastion security group
  #########################################
  module "sg-bastion" {

    source         = "/var/terraform/modules/sgroup/"
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
    cidr_blocks       = ["103.166.244.252/32"]
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


    ###############################################
    # Template
    ###############################################


    data "template_file" "frontend" {
      template = file("${path.module}/userdata.sh")
      vars = {
        localaddress = "${aws_instance.backend.private_ip}"
      }
    }


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
