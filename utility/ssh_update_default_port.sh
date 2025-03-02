#!/bin/bash

if [ -p "$1" ]; then
    echo "Usage: $0 <port_number>"
    exit 1
fi

new_port="$1"

if ! [[ "$new_port" =~ ^[0-9]+$ ]]; then
    echo "Error: Port number must be a positive integer."
    exit 1
fi

sudo perl -pi -e 's/^#?Port 22$/Port $new_port/' /etc/ssh/sshd_config
sudo sed -E -i 's|^#?(PasswordAuthentication)\s.*|\1 no|' /etc/ssh/sshd_config

if ! grep '^PasswordAuthentication\s' /etc/ssh/sshd_config; then 
    echo 'PasswordAuthentication no' | sudo tee -a /etc/ssh/sshd_config; 
fi

sudo systemctl disable ssh.socket
sudo systemctl enable ssh
sudo reboot