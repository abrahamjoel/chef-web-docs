#!/bin/bash

chef_automate_fqdn=$1

apt-get update
apt-get -y install curl

# Ensure the time is up to date
apt-get -y install ntp
service ntp stop
ntpdate -s time.nist.gov
service ntp start

# Install Chef server
if [ ! $(which chef-server-ctl) ]
  then
    # Download the package
    if [ ! -d ~/downloads ]
      then
        mkdir ~/downloads
    fi
    wget -P ~/downloads https://packages.chef.io/stable/ubuntu/14.04/chef-server-core_12.11.0-1_amd64.deb

    # Install the package
    dpkg -i ~/downloads/chef-server-core_12.11.0-1_amd64.deb

    # Configure and restart services
    chef-server-ctl reconfigure
    chef-server-ctl restart

    # Wait for all services to come online
    until (curl -D - http://localhost:8000/_status) | grep "200 OK"; do sleep 15s; done
    while (curl http://localhost:8000/_status) | grep "fail"; do sleep 15s; done

    # Create an initial user
    chef-server-ctl user-create admin Bob Admin admin@4thcoffee.com P4ssw0rd! --filename /tmp/admin.pem
    chef-server-ctl org-create 4thcoffee 'Fourth Coffee, Inc.' --filename 4thcoffee-validator.pem -a admin

    # Create Chef Automate user and organization
    chef-server-ctl user-create delivery Delivery Admin delivery@4thcoffee.com P4ssw0rd! --filename /tmp/delivery.pem
    chef-server-ctl org-create cohovineyard 'Coho Vineyard' --filename cohovineyard-validator.pem -a delivery
fi
