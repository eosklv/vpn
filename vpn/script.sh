#!/bin/bash
# A bootscript for VPN server
sudo apt update
sudo apt install openvpn easy-rsa unzip

cd ~
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf ./aws*

export EASYRSA_BATCH=1

mkdir ~/easy-rsa
ln -s /usr/share/easy-rsa/* ~/easy-rsa/
chmod 700 ~/easy-rsa
~/easy-rsa/easyrsa init-pki

cat << EOF >> ~/easy-rsa/vars
set_var EASYRSA_REQ_COUNTRY    "KZ"
set_var EASYRSA_REQ_PROVINCE   "VKO"
set_var EASYRSA_REQ_CITY       "UKG"
set_var EASYRSA_REQ_ORG        "eugeny"
set_var EASYRSA_REQ_EMAIL      "e.sokolov.mail@gmail.com"
set_var EASYRSA_REQ_OU         "IT"
set_var EASYRSA_ALGO "ec"
set_var EASYRSA_DIGEST "sha512"
EOF

~/easy-rsa/easyrsa build-ca nopass
sudo cp ~/pki/ca.crt /etc/openvpn/server/

~/easy-rsa/easyrsa gen-req server nopass
sudo cp ~/pki/private/server.key /etc/openvpn/server/

~/easy-rsa/easyrsa sign-req server server
sudo cp ~/pki/issued/server.crt /etc/openvpn/server/

openvpn --genkey secret ta.key
sudo cp ~/ta.key /etc/openvpn/server/

mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs

~/easy-rsa/easyrsa gen-req client nopass
cp ~/pki/private/client.key ~/client-configs/keys/

~/easy-rsa/easyrsa sign-req client client
cp ~/pki/issued/client.crt ~/client-configs/keys/

cp ~/ta.key ~/client-configs/keys/
sudo cp /etc/openvpn/server/ca.crt ~/client-configs/keys/
sudo chown ubuntu.ubuntu ~/client-configs/keys/*

sudo aws s3 cp s3://esklv-vpn/configs/server.conf /etc/openvpn/server/

sudo sed -i 's/#\(net.ipv4.ip_forward\)/\1/' /etc/sysctl.conf
sudo sysctl -p

sudo systemctl -f enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service

mkdir -p ~/client-configs/files
aws s3 cp s3://esklv-vpn/configs/base.conf ~/client-configs/
ip_address=`curl ipinfo.io/ip`
sed -i "s/my-server-1/${ip_address}/" ~/client-configs/base.conf

aws s3 cp s3://esklv-vpn/configs/make_config.sh ~/client-configs/
chmod 700 ~/client-configs/make_config.sh
~/client-configs/make_config.sh client
aws s3 cp ~/client-configs/files/client.ovpn s3://esklv-vpn/profiles/