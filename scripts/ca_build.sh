#!/bin/bash
# Init PKI and build CA
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