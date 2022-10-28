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
