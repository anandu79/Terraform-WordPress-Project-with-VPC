# Terraform WordPress Project with VPC

Here, I have created a WordPress website using Terraform! 

I have created a VPC with 3 public subnets, 3 private subnets, a public and private route table, 1 internet gateway, and one NAT gateway.

I have also launched 3 instances which are : bastion, frontend, and backend instances. Among them, WordPress is installed in the frontend instance, database is installed in the backend instance, and the bastion instance will provide SSH access into the frontend and backend instances from the allowed IP address.

After applying this code, we will receive a WordPress installation page in our domain :)
