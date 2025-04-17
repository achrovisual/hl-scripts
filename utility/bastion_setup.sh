#!/bin/bash

# Update host
sudo apt update
sudo apt upgrade -y

# Install VSCode
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
sudo apt install apt-transport-https
sudo apt update
sudo apt install code # or code-insiders