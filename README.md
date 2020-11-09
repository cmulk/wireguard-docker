# wireguard-docker
Wireguard setup in Docker meant for a simple personal VPN.
There are currently 3 flavors:
 - buster -  `docker pull cmulk/wireguard-docker:buster`
 - stretch - `docker pull cmulk/wireguard-docker:stretch`
 - alpine -  `docker pull cmulk/wireguard-docker:alpine`  _(install-module not supported on alpine)_

Use the flavor (buster or stretch) that corresponds to your host machine if the kernel module install feature is going to be used.

## Overview
This docker image and configuration is my simple version of a wireguard personal VPN, used for the goal of security over insecure (public) networks, not necessarily for Internet anonymity. The debian (stretch and buster) flavors of the image have the ability to install the wireguard kernel module on the host, and the host OS must also use the same version of debian if this feature is going to be used. In addition, the host's /lib/modules directory needs to be mounted on the first run to install the module (see the [Running](#Running) section below). Thanks to [activeeos/wireguard-docker](https://github.com/activeeos/wireguard-docker) for the general structure of the docker image - it is the same concept just built on Ubuntu 16.04.

In my use case, I'm running the wireguard docker image on a free-tier Google Cloud Platform debian virtual machine and connect to it with Android, Linux, and a GL-Inet router as clients.

## Running
### First Run (stretch or buster only)
If the wireguard kernel module is not already installed on the __host__ system, use this first run command to install it:
```
docker run -it --rm --cap-add sys_module -v /lib/modules:/lib/modules cmulk/wireguard-docker:buster install-module
```

### Normal Run
```
docker run --cap-add net_admin --cap-add sys_module -v <config volume or host dir>:/etc/wireguard -p <externalport>:<dockerport>/udp cmulk/wireguard-docker:buster
```
Example:
```
docker run --cap-add net_admin --cap-add sys_module -v wireguard_conf:/etc/wireguard -p 5555:5555/udp cmulk/wireguard-docker:buster
```
### Generate Keys
This shortcut can be used to generate and display public/private key pairs to use for the server or clients
```
docker run -it --rm cmulk/wireguard-docker:buster genkeys
```

## Configuration
Sample server-side interface configuration to go in `/etc/wireguard` (e.g., `wg0.conf`):
```
[Interface]
Address = 192.168.20.1/24
PrivateKey = <server_private_key>
ListenPort = 5555

[Peer]
PublicKey = <client_public_key>
AllowedIPs = 192.168.20.2
```
Sample client configuration:
```
[Interface]
Address = 192.168.20.2/24
PrivateKey = <client_private_key>
ListenPort = 0 #needed for some clients to accept the config

[Peer]
PublicKey = <server_public_key>
Endpoint = <server_public_ip>:5555
AllowedIPs = 0.0.0.0/0,::/0 #makes sure ALL traffic routed through VPN
PersistentKeepalive = 25
```
## Other Notes
- This Docker image also has a iptables NAT (MASQUERADE) rule already configured to make traffic through the VPN out to the Internet work. This can be disabled by setting the environment variable `IPTABLES_MASQ=0`.
- For some clients (a GL.inet router in my case) you may have trouble with HTTPS (SSL/TLS) due to the MTU on the VPN. Ping and HTTP work fine but HTTPS does not for some sites. This can be fixed with [MSS Clamping](https://www.tldp.org/HOWTO/Adv-Routing-HOWTO/lartc.cookbook.mtu-mss.html). This is simply a checkbox in the OpenWRT Firewall settings interface.
- It's possible to watch for changes to any of the configuration files in `/etc/wireguard` (in the container) and automatically restart wireguard as soon as one changes. This is very useful when combining this docker image with a wireguard GUI. To enable watching for changes, set the environment variable `WATCH_CHANGES=1`.

## Use as client
- This image can be used as a "client" as well. If you want to forward all traffic through the VPN (`AllowedIPs = 0.0.0.0/0`), you need to use the `--privileged` flag when running the container, or you got error `Read-only file system`.
- If you got error `RTNETLINK answers: Permission denied`, you need to use the `--sysctl net.ipv6.conf.all.disable_ipv6=0` flag.

### Client example
```
docker run -d \
--privileged \
--restart=always \
--name wireguard-client \
--cap-add NET_ADMIN \
--cap-add SYS_MODULE \
--sysctl net.ipv6.conf.all.disable_ipv6=0 \
-v <client config dir>wg0.conf:/etc/wireguard/wg0.conf \
cmulk/wireguard-docker:alpine
```

### Example connect to client from another container
```
docker run -it --rm --net=container:wireguard-client alpine wget -q -O - ipinfo.io/ip
```

## docker-compose
Sample docker-compose.yml
```yaml
version: "2"
services:
 vpn:
  image: cmulk/wireguard-docker:buster
  volumes:
   - /etc/wireguard:/etc/wireguard
  networks:
   - net
  ports:
   - 5555:5555/udp
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
   - SYS_MODULE

networks:
  net:
```
## Build
Since the images are already on Docker Hub, you only need to do this if you want to change something
```sh
git clone https://github.com/cmulk/wireguard-docker.git
cd wireguard-docker

docker build -f Dockerfile.buster -t wireguard:local .
### OR ###
docker build -f Dockerfile.stretch -t wireguard:local .
### OR ###
docker build -f Dockerfile.alpine -t wireguard:local .
```
