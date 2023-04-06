#! /bin/bash
# Set variables supplied by Terraform
WORDPRESS_ADMIN_SECRET_ID="${wordpress_admin_secret_id}"
WORDPRESS_PASSWORD_SECRET_ID="${wordpress_password_secret_id}"
WORDPRESS_RDS_HOST_ID="${wordpress_rds_host_id}"
WEBSITE_ASSET_BUCKET="${website_asset_bucket}"
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"

echo "----------- Print config values    -----------"
echo $WORDPRESS_ADMIN_SECRET_ID
echo $WORDPRESS_PASSWORD_SECRET_ID
echo $WORDPRESS_RDS_HOST

# Install SSM
sudo systemctl start amazon-ssm-agent

echo "----------- Starting WordPress install    -----------"
set +v

# Install services
sudo yum update -y
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum update -y
sudo yum install -y yum-utils

sudo yum-config-manager --disable 'remi-php*'
sudo yum-config-manager --enable remi-php81

sudo yum install
sudo yum install mysql -y
sudo yum install php81 php81-php-fpm php81-php-mysqlnd -y
sudo yum install jq git -y
sudo amazon-linux-extras install nginx1 -y

# Install WP-CLI
(cd /tmp && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar)
sudo chmod +x /tmp/wp-cli.phar
sudo mv /tmp/wp-cli.phar /usr/local/bin/wp

export PATH=$PATH:/usr/local/bin
source ~/.bashrc
sudo rm /usr/bin/php
sudo ln -s /bin/php81 /usr/bin/php

# Fetch NGINX from S3
aws s3 cp s3://$WEBSITE_ASSET_BUCKET/config/nginx/nginx.conf /etc/nginx/nginx.conf
aws s3 cp s3://$WEBSITE_ASSET_BUCKET/config/nginx/wordpress.conf /etc/nginx/conf.d/wordpress.conf

# Configure PHP-FPM
# /etc/opt/remi/php81/php-fpm.d/www.conf

sudo sed -i 's/user = apache/user = nginx/g' /etc/opt/remi/php81/php-fpm.d/www.conf
sudo sed -i 's/group = apache/group = nginx/g' /etc/opt/remi/php81/php-fpm.d/www.conf
sudo sed -i 's/;listen.owner = apache/listen.owner = nginx/g' /etc/opt/remi/php81/php-fpm.d/www.conf
sudo sed -i 's/;listen.group = apache/listen.group = nginx/g' /etc/opt/remi/php81/php-fpm.d/www.conf
sudo sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/opt/remi/php81/php-fpm.d/www.conf

sudo sed -i 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g' /etc/opt/remi/php81/php-fpm.d/www.conf

# Create WWW group
sudo groupadd www
sudo usermod -aG www ec2-user
sudo usermod -aG www nginx

# Download and position WordPress
sudo mkdir -p /var/www/html
sudo wget https://wordpress.org/latest.tar.gz -P /var/www
cd /var/www
sudo tar -xvzf latest.tar.gz
sudo mv /var/www/wordpress/* /var/www/html

# Set permissions for WordPress
sudo chgrp www -R /var/www/html
sudo chown nginx -R /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;

echo "----------- Fetching credentials      -----------"
export WORDPRESS_ADMIN=$(aws secretsmanager get-secret-value --secret-id=$WORDPRESS_ADMIN_SECRET_ID --region=$EC2_REGION | jq -r .SecretString)
export WORDPRESS_PASSWORD=$(aws secretsmanager get-secret-value --secret-id=$WORDPRESS_PASSWORD_SECRET_ID --region=$EC2_REGION | jq -r .SecretString)
export WORDPRESS_RDS_HOSTNAME=$(aws rds describe-db-instances --db-instance-identifier=$WORDPRESS_RDS_HOST_ID --region=$EC2_REGION | jq -r '.DBInstances[].Endpoint.Address')
echo $WORDPRESS_RDS_HOSTNAME

sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

sudo sed -i 's/database_name_here/wordpress/g' /var/www/html/wp-config.php
sudo sed -i 's/username_here/'$WORDPRESS_ADMIN'/g' /var/www/html/wp-config.php
sudo sed -i 's/password_here/'$WORDPRESS_PASSWORD'/g' /var/www/html/wp-config.php
sudo sed -i 's/localhost/'$WORDPRESS_RDS_HOSTNAME'/g' /var/www/html/wp-config.php
sudo sed -i 's/put your unique phrase here/lolsabub/g' /var/www/html/wp-config.php


echo "----------- Installing WP-CLI and plugins -----------"
aws s3 cp s3://$WEBSITE_ASSET_BUCKET/config/wordpress/plugins.list /tmp

cd /var/www/html/
while read plugin; do
  wp plugin install $plugin --activate
done </tmp/plugins.list

echo "----------- Installing theme              -----------"
(cd /var/www/html/wp-content/themes && git clone https://github.com/BurendoUK/burendo-website.git)
mv /var/www/html/wp-content/themes/burendo-website /var/www/html/wp-content/themes/burendo

echo "----------- Starting web services         -----------"

# Start services
sudo service php81-php-fpm start
sudo service nginx start

sudo chgrp www /var/run/php-fpm.sock

echo "----------- Finished WordPress install    -----------"
trap echo "----------- ERROR WordPress install    -----------" EXIT
