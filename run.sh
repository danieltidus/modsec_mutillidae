#!/bin/bash

# Iniciar MySQL
echo "Starting MySQL..."
usermod -d /var/lib/mysql/ mysql
service mysql start

echo "Starting php..."
service php8.1-fpm start

# Esperar MySQL iniciar completamente
sleep 5

# Criar um banco de dados no MySQL
DB_NAME="mutillidae"

mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
mysql -u root -e "FLUSH PRIVILEGES;"


# Iniciar Apache2
echo "Starting Apache2..."
service apache2 start

tail -f /var/log/apache2/error.log /var/log/apache2/access.log
