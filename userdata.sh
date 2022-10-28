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
