#!/bin/bash
# Generate requests
export EASYRSA_BATCH=1

mkdir ~/easy-rsa
ln -s /usr/share/easy-rsa/* ~/easy-rsa/
chmod 700 ~/easy-rsa
~/easy-rsa/easyrsa init-pki

cat << EOF >> ~/easy-rsa/vars
set_var EASYRSA_ALGO "ec"
set_var EASYRSA_DIGEST "sha512"
EOF

~/easy-rsa/easyrsa build-ca nopass
sudo cp ~/pki/ca.crt /etc/openvpn/server/

~/easy-rsa/easyrsa gen-req server nopass
sudo cp ~/pki/private/server.key /etc/openvpn/server/

~/easy-rsa/easyrsa gen-req client nopass
cp ~/pki/private/client.key ~/client-configs/keys/


