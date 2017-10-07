#!/usr/bin/env bash

# Automate installing an apache server on Ubuntu 16.04 (may work on other versions).
# This is for a dev environment, and may not be (probably isn't) suitable for production.
# This was done with CakePHP in mind, because I had a lot of problems with it in Ubuntu.

# Settings
    username="vagrant"
    mysqlpassword="password"

# Exit if not being run as root.
    if [[ $(id -u) -ne 0 ]] ; then 
        echo "This script must be run as root."
        exit 1
    fi  

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

apt-get update
apt-get upgrade -y
apt-get install -y apache2
apt-get install -y php libapache2-mod-php
apt-get install -y php-intl php-zip php-mbstring php-mysql
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${mysqlpassword}"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${mysqlpassword}"
apt-get install -y mysql-server
mysql -uroot -p$mysqlpassword -e "source $DIR/mysqlsetup.sql"
apt-get install -y composer

# Set log file to /var/log/php_errors.log.  Can view recent changes with "tail /var/log/php_errors.log"
    # ini file is probably /etc/php/7.0/apache2/php.ini, but could change in future versions.
    fileName=$(php -r "echo php_ini_loaded_file();")
    replace="apache2"
    fileName="${fileName/cli/$replace}"
    #fileName has "cli" instead of "apache2" for some reason, and that doesn't work.

    logDir="/var/log/"
    logFile="${logDir}php_errors.log"

    echo "error_reporting = E_ALL | E_STRICT" >> $fileName
    echo "error_log = ${logFile}" >> $fileName
    echo "log_errors = On" >> $fileName

    touch $logFile
    chown -R www-data:www-data $logDir
    chmod +rw $logFile

# Enable url rewriting
    a2enmod rewrite
    service apache2 reload

# Change www directory if in Vagrant.
if [ "$IN_VAGRANT" ]; then
    rm -rf /var/www
    ln -fs /vagrant/www /var/www
    perl -pi -e "s/www-data/vagrant/g" /etc/apache2/envvars
fi

# Set user to be able to edit www-data.  Skip for Vagrant.

if ! [ "$IN_VAGRANT" ]; then
    sudo adduser $username www-data
    sudo chown -R www-data:www-data /var/www
    sudo chmod -R g=rwx /var/www
fi

# Restart apache2 service
    service apache2 restart

# Show end messages
    echo -e "\nPHP error log is now /var/log/php_errors.log.\n"
    echo -e "\nImportant!  You will need to log out and back in before you can edit /var/www."
    echo -e "\nImportant!  You will still need to edit /etc/apache2/apache2.conf and change AllowOverride to \"All\" in the /var/www section."

