#!/bin/bash
# A bootscript for server
sudo apt update
sudo apt install openvpn easy-rsa unzip -y

curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o ~/"awscliv2.zip"
unzip ~/awscliv2.zip
sudo ./aws/install
rm -rf ~/aws*