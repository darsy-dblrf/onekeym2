#!/bin/bash
# Author:  Darsy < darsychen AT gmail.com>
# company:  https://dblrf.com
#
# Notes: onekeyup

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
clear
printf "
#######################################################################
#       Onekeyup for lastes Ubuntu LTS version to Install Magento2    #
#       For more information please visit https://www.dblrf.com       #
#######################################################################
"

# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }


#input variable
read -e -p "Please input domain(example: www.magento2.com): " domain
read -e -p "Please input Database username(example: mg2user): " dbuser
read -e -p "Please input Database name(example: mg2db): " dbname
read -e -p "Please input magento admin username(example: admin): " admin
read -e -p "Please input magento admin password(example: adminpassword): " adminpassword
dbpassword=`openssl rand -base64 12`

#start install
apt update
apt upgrade -y
apt install apt-transport-https git -y
apt-get install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version=10.4 --skip-maxscale
apt install mariadb-server  mariadb-client -y
curl -sSL https://get.docker.com | bash
docker run -d -p 9200:9200 -p 9300:9300 -p 5601:5601 --restart=always --name eskibana nshou/elasticsearch-kibana


mysql -e "create database $dbname;"
mysql -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpassword';"
mysql -e "grant all privileges on $dbname.* TO '$dbuser'@'localhost';"
mysql -e "flush privileges;"

apt install nginx php7.4-fpm php7.4-common php7.4-mysql php7.4-gmp php7.4-curl php7.4-intl php7.4-bcmath php7.4-soap php7.4-mbstring php7.4-xmlrpc php7.4-gd php7.4-xml php7.4-cli php7.4-zip -y

sed -i 's/max_execution_time = 30/max_execution_time = 600/g' /etc/php/7.4/fpm/php.ini
sed -i 's/max_input_time = 60/max_input_time = 600/g' /etc/php/7.4/fpm/php.ini
sed -i 's/emory_limit = 128M/emory_limit = 512M/g' /etc/php/7.4/fpm/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php/7.4/fpm/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo = 0/g' /etc/php/7.4/fpm/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 128M/g' /etc/php/7.4/fpm/php.ini
sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/g' /etc/php/7.4/fpm/php.ini
sed -i 's/disable_functions/;disable_functions/g' /etc/php/7.4/fpm/php.ini
systemctl restart php7.4-fpm
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer


mkdir -p /var/www/magento2
git clone -b 2.4 https://github.com/magento/magento2.git /var/www/magento2
chown -R www-data.www-data /var/www/magento2
cd /var/www/magento2
sudo -u www-data composer install
cd /root/

cat > /etc/nginx/sites-enabled/$domain.conf<< EOF
upstream fastcgi_backend {
    server   unix:/var/run/php/php7.4-fpm.sock;
}

server {
    listen 80;
    listen [::]:80;

    server_name  $domain www.$domain;
    index  index.php;

    set \$MAGE_ROOT /var/www/magento2;
    set \$MAGE_MODE production;

    access_log /var/log/nginx/$domain-access.log;
    error_log /var/log/nginx/$domain-error.log;

    include /var/www/magento2/nginx.conf.sample;
}
EOF

systemctl restart nginx
cd /var/www/magento2
php bin/magento setup:install \
--base-url="$domain" \
--db-host="localhost" \
--db-name="$dbname" \
--db-user="$dbuser" \
--db-password="$dbpassword" \
--admin-firstname="admin" \
--admin-lastname="admin" \
--admin-email="admin@domain" \
--admin-user="$admin" \
--admin-password="$adminpassword" \
--language="en_US" \
--currency="USD" \
--timezone="Aisa/Shanghai" \
--use-rewrites="1" \
--backend-frontname="admin_portal" \
--elasticsearch-host="127.0.0.1" \
--elasticsearch-index-prefix="$domain"
