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
dbpassword=`openssl rand -base64 12`

#start install
apt update
apt upgrade -y
apt install apt-transport-https -y
apt-get install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version=10.4 --skip-maxscale
apt install mariadb-server  mariadb-client -y
curl -sSL https://get.docker.com | bash

mysql -e "create database $dbname;"
mysql -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpassword';"
mysql -e "grant all privileges on $dbname.* TO '$dbuser'@'localhost';"
mysql -e "flush privileges;"