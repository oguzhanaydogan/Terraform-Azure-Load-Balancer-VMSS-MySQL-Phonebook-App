#!/bin/bash

# Install Python and pip
apt-get update
apt-get install -y python3 python3-pip

# Install Flask and pyodbc
pip3 install Flask pyodbc

# Alternatively, you can copy the file to the instance using a different method
git clone https://github.com/oguzhanaydogan/terraform-lb-phonebook-app.git /home/clouduser/terraform-lb-phonebook-app/
cd /home/clouduser/terraform-lb-phonebook-app/

# Start the Phonebook Application
python3 phonebook-app.py
