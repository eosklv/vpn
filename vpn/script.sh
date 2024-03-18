#!/bin/bash
# A bootscript for VPN server
sudo apt update
sudo apt install openvpn easy-rsa unzip -y

curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o /home/ubuntu/"awscliv2.zip"
unzip /home/ubuntu/awscliv2.zip
sudo ./aws/install
rm -rf /home/ubuntu/aws*

export EASYRSA_BATCH=1

mkdir /home/ubuntu/easy-rsa
ln -s /usr/share/easy-rsa/* /home/ubuntu/easy-rsa/
chmod 777 /home/ubuntu/easy-rsa
/home/ubuntu/easy-rsa/easyrsa init-pki

cat << EOF >> /home/ubuntu/easy-rsa/vars
set_var EASYRSA_REQ_COUNTRY    "KZ"
set_var EASYRSA_REQ_PROVINCE   "VKO"
set_var EASYRSA_REQ_CITY       "UKG"
set_var EASYRSA_REQ_ORG        "eugeny"
set_var EASYRSA_REQ_EMAIL      "e.sokolov.mail@gmail.com"
set_var EASYRSA_REQ_OU         "IT"
set_var EASYRSA_ALGO "ec"
set_var EASYRSA_DIGEST "sha512"
EOF

/home/ubuntu/easy-rsa/easyrsa build-ca nopass
sudo cp /home/ubuntu/pki/ca.crt /etc/openvpn/server/

/home/ubuntu/easy-rsa/easyrsa gen-req server nopass
sudo cp /home/ubuntu/pki/private/server.key /etc/openvpn/server/

/home/ubuntu/easy-rsa/easyrsa sign-req server server
sudo cp /home/ubuntu/pki/issued/server.crt /etc/openvpn/server/

openvpn --genkey secret ta.key
sudo cp /home/ubuntu/ta.key /etc/openvpn/server/

mkdir -p /home/ubuntu/client-configs/keys
chmod -R 700 /home/ubuntu/client-configs

/home/ubuntu/easy-rsa/easyrsa gen-req client nopass
cp /home/ubuntu/pki/private/client.key /home/ubuntu/client-configs/keys/

/home/ubuntu/easy-rsa/easyrsa sign-req client client
cp /home/ubuntu/pki/issued/client.crt /home/ubuntu/client-configs/keys/

cp /home/ubuntu/ta.key /home/ubuntu/client-configs/keys/
sudo cp /etc/openvpn/server/ca.crt /home/ubuntu/client-configs/keys/
sudo chown ubuntu.ubuntu /home/ubuntu/client-configs/keys/*

sudo aws s3 cp s3://esklv-vpn/configs/server.conf /etc/openvpn/server/

sudo sed -i 's/#\(net.ipv4.ip_forward\)/\1/' /etc/sysctl.conf
sudo sysctl -p

sudo systemctl -f enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service

mkdir -p /home/ubuntu/client-configs/files
aws s3 cp s3://esklv-vpn/configs/base.conf /home/ubuntu/client-configs/
ip_address=`curl ipinfo.io/ip`
sed -i "s/my-server-1/${ip_address}/" /home/ubuntu/client-configs/base.conf

aws s3 cp s3://esklv-vpn/configs/make_config.sh /home/ubuntu/client-configs/
chmod 700 /home/ubuntu/client-configs/make_config.sh
/home/ubuntu/client-configs/make_config.sh client
aws s3 cp /home/ubuntu/client-configs/files/client.ovpn s3://esklv-vpn/profiles/