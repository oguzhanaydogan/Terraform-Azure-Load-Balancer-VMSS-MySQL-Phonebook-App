#!/bin/bash

# Install Python and pip
sudo add-apt-repository -y ppa:jblgf0/python
sudo apt-get update
sudo apt-get install python3.6 -y
sudo apt install python3-pip -y



# Install Flask and pyodbc
# sudo pip3 install Flask pyodbc

pip3 install flask
pip3 install flask_mysql
pip3 install mysql-connector-python

# Alternatively, you can copy the file to the instance using a different method
git clone https://github.com/oguzhanaydogan/terraform-lb-phonebook-app.git /home/clouduser/terraform-lb-phonebook-app/
cd /home/clouduser/terraform-lb-phonebook-app/

# Start the Phonebook Application
python3.6 phonebook-app.py



# yum update -y
# yum install python3 -y
# pip3 install flask
# pip3 install flask_mysql
# yum install git -y