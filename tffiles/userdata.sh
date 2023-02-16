#!/bin/bash

# Install Python and pip
apt-get update
apt-get install -y python3 python3-pip

# Install Flask and pyodbc
pip3 install Flask pyodbc

# Download the Phonebook Application code
wget https://raw.githubusercontent.com/oguzhanaydogan/repo/main/phonebook-app.py
# Alternatively, you can copy the file to the instance using a different method

# Set the environment variables for the SQL Database
export SQL_SERVER_NAME=your_server_name
export SQL_DATABASE_NAME=your_database_name
export SQL_USERNAME=your_username
export SQL_PASSWORD=your_password

# Start the Phonebook Application
python3 phonebook-app.py
