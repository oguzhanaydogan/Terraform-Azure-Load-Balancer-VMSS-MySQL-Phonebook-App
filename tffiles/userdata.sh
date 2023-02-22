#!/bin/bash

# Install Python and pip
sudo apt-get update
sudo apt install python3-pip -y

# pip3 install Flask
pip3 install flask
pip3 install flask_mysql

# Alternatively, you can copy the file to the instance using a different method
git clone https://github.com/oguzhanaydogan/terraform-lb-phonebook-app.git /home/clouduser/terraform-lb-phonebook-app/
cd /home/clouduser/terraform-lb-phonebook-app/

# Start the Phonebook Application
sudo python3 phonebook-app.py


