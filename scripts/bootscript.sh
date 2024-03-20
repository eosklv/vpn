#!/bin/bash

# Configuring OpenVPN Server

sudo apt install openvpn easy-rsa -y

export EASYRSA_BATCH=1

mkdir ~/easy-rsa
ln -s /usr/share/easy-rsa/* ~/easy-rsa/
chmod 700 ~/easy-rsa
cd ~/easy-rsa
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

~/easy-rsa/easyrsa build-server-full server nopass
~/easy-rsa/easyrsa build-client-full client nopass

openvpn --genkey secret ~/easy-rsa/ta.key

sudo cp ~/pki/issued/server.crt ~/pki/private/server.key \
	~/pki/ca.crt ~/easy-rsa/ta.key /etc/openvpn/server/

mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs

cp ~/easy-rsa/ta.key ~/pki/issued/client.crt ~/pki/private/client.key \
	~/pki/ca.crt ~/client-configs/keys/

sudo chown ubuntu.ubuntu ~/client-configs/keys/*

sudo aws s3 cp s3://esklv-vpn/configs/server.conf /etc/openvpn/server/

sudo sed -i "s/#\(net.ipv4.ip_forward\)/\1/" /etc/sysctl.conf
sudo sysctl -p

sudo aws s3 cp s3://esklv-vpn/configs/before.rules /etc/ufw/
iface=$(ip route list default | awk '{ print $5 }')
sudo sed -i "s/ eth0 / ${iface} /" /etc/ufw/before.rules

sudo sed -i 's/\(DEFAULT_FORWARD_POLICY *= *\).*/\1"ACCEPT"/' /etc/default/ufw

sudo ufw allow 443/tcp
sudo ufw allow OpenSSH
sudo ufw disable
sudo ufw enable

sudo systemctl -f enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service

mkdir -p ~/client-configs/files
aws s3 cp s3://esklv-vpn/configs/base.conf ~/client-configs/
ip_address=`curl ipinfo.io/ip`
sed -i "s/my-server-1/${ip_address}/" ~/client-configs/base.conf
 
cat ~/client-configs/base.conf \
    <(echo -e '<ca>') \
    ~/client-configs/keys/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ~/client-configs/keys/client.crt \
    <(echo -e '</cert>\n<key>') \
    ~/client-configs/keys/client.key \
    <(echo -e '</key>\n<tls-crypt>') \
    ~/client-configs/keys/ta.key \
    <(echo -e '</tls-crypt>') \
    > ~/client-configs/files/client.ovpn

aws s3 cp ~/client-configs/files/client.ovpn s3://esklv-vpn/profiles/