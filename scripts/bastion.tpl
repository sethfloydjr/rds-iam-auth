#!/bin/bash -x

#Setup psql client
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt update
apt install -y postgresql-client

#Setup mysql client
apt install -y mysql-client

#Install AWS CLI
apt  install -y awscli

#Pull down the RDS Global certificate
cd /opt
wget "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem"