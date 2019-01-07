#!/bin/bash

## The below is modified from https://github.com/activeeos/wireguard-docker

# Find a Wireguard interface
interfaces=`find /etc/wireguard -type f`
if [[ -z $interfaces ]]; then
    echo "$(date): Interface not found in /etc/wireguard" >&2
    exit 1
fi


for interface in $interfaces; do
    echo "$(date): Starting Wireguard $interface"
    wg-quick up $interface
done

# Add masquerade rule for NAT'ing VPN traffic bound for the Internet
echo "Adding iptables NAT rule"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Handle shutdown behavior
finish () {
    echo "$(date): Shutting down Wireguard"
    for interface in $interfaces; do
        wg-quick down $interface
    done
    iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
    exit 0
}

trap finish SIGTERM SIGINT SIGQUIT

sleep infinity &
wait $!
