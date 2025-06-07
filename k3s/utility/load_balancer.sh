#!/bin/bash

# Update 
sudo apt update
sudo apt upgrade -y

# Install HAProxy and keepalived
sudo apt-get install haproxy keepalived

# Configure HAProxy

# Configure keepalived