#!/bin/bash
# Import and sign requests
~/easy-rsa/easyrsa sign-req server server
sudo cp ~/pki/issued/server.crt /etc/openvpn/server/

~/easy-rsa/easyrsa sign-req client client
cp ~/pki/issued/client.crt ~/client-configs/keys/