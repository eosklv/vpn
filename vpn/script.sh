#!/bin/bash
# A bootscript for VPN server
sudo apt update
sudo apt install openvpn easy-rsa unzip

cd ~
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf ./aws*