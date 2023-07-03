#!/bin/bash

SERVER_CONFIG_FILE="<SERVER_WIREGUARD_CONFIG_FILE>"
SERVER_IP="<SERVER_IP_ADDRESS>"

echo "Input config name"
read config_name

# Generating private and public key
private_key=$(wg genkey)
public_key=$(echo "$private_key" | wg pubkey)

# Getting last added ip address from SERVER_WIREGUARD_CONFIG_FILE
ip=$(tail -n 1 wg0.conf | awk '{print $3}' | awk -F '/' '{print $1}')

# Generating new ip address
current_interface_id=$(echo "$ip" | awk -F '.' '{print $4}')
next_interface_id=$((current_interface_id+1))
next_ip=$"${ip%.*}.$next_interface_id/32"

# Adding a record to SERVER_WIREGUARD_CONFIG_FILE file
echo "

[Peer]
PublicKey = $public_key
AllowedIPs = $next_ip" >> "$SERVER_CONFIG_FILE"

# Generating client config file
echo "[Interface]
PrivateKey = $private_key
Address = $next_ip
DNS = 8.8.8.8

[Peer]
PublicKey = $(cat /etc/wireguard/publickey)
Endpoint = $SERVER_IP:51830
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 20" > "$config_name"

# Restarting wireguard serivce
systemctl restart wg-quick@wg0.service
systemctl status wg-quick@wg0.service
