instance_type            = "t2.micro"
instance_ami             = "ami-0e6329e222e662a52"
aws_region               = "ap-south-1"
aws_access_key           = "AKIAUIA7DWAU5HKL3FKC"
aws_secret_key           = "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"
project_vpc_cidr         = "172.16.0.0/16"
project_name             = "terraform"
project_environment      = "dev"
project_subnets          = 3
frontend-webaccess-ports = [80, 443]
hosted_zone              = "Z05575286GQXTFTADPNF"

mysql_root_password  = "mysqlroot123"
mysql_extra_username = "wordpress"
mysql_extra_password = "wordpress"
mysql_extra_dbname   = "wordpress"
mysql_extra_host     = "%"
