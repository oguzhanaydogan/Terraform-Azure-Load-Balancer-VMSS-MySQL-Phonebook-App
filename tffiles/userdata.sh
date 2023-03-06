#!/bin/bash

# Install Python and pip
sudo apt-get update
sudo apt install python3-pip -y

# pip3 install Flask
pip3 install flask
pip3 install flask_mysql

# Alternatively, you can copy the file to the instance using a different method
git clone https://github.com/oguzhanaydogan/Terraform-Azure-Load-Balancer-VMSS-MySQL-Phonebook-App.git /home/clouduser/Terraform-Azure-Load-Balancer-VMSS-MySQL-Phonebook-App/
cd /home/clouduser/Terraform-Azure-Load-Balancer-VMSS-MySQL-Phonebook-App/

# Start the Phonebook Application
sudo python3 phonebook-app.py


