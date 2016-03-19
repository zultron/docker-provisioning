# Debian Provisioning System in Docker

- [Introduction](#introduction)
- [Getting started](#getting-started)
- [Squid](#squid)
- [DHCPD](#dhcpd)
- [Common Commands](#common-commands)

## Introduction

`Dockerfile` to create a set of [Docker](https://www.docker.com/)
container images for provisioning Debian hosts.

This is a WIP.

Pieces in place:

- DHCPD:  a DHCP/BOOTP server for booting new hosts from BIOS
- Squid:  a caching proxy for Debian/Ubuntu packages, based on
[squid-deb-proxy][sdb]

[sdb]: https://packages.debian.org/jessie/squid-deb-proxy

Pieces planned:

- TFTP server for downloading kernels and install images
- HTTP server for serving preseed files

## Getting started

Build the image:

```bash
git clone https://github.com/zultron/docker-provisioning.git
cd docker-provisioning
docker build --tag $USER/provision .
```

## Squid

Create the cache directory and the container:

```bash
mkdir -p /srv/docker/squid/debcache
docker create --name squid --hostname squid --publish 8000:8000 \
	--volume /srv/docker/squid/debcache:/var/cache/squid-deb-proxy \
	--volume /srv/docker/squid/log:/var/log/supervisor \
	$USER/provision
```

Start Squid:

```bash
docker start squid
```

To use the proxy, create a file in `/etc/apt/apt.conf.d/01proxy` with
these contents:

```
Acquire::http::Proxy "http://localhost:8000";
```

## DHCPD

Set up an interface with an IP address and create the container:

```bash
sudo ifconfig eth0 10.254.239.1 netmask 255.255.255.0
docker create --name dhcpd --hostname dhcpd \
	--volume /srv/docker/dhcpd/log:/var/log/supervisor \
	--publish 10.254.239.1:67:67/udp $USER/provision
```

Start Dhcpd:

```bash
docker start dhcpd
```

To use the proxy, create a file in `/etc/apt/apt.conf.d/01proxy` with
these contents:

```
Acquire::http::Proxy "http://localhost:8000";
```

## Common Commands

Start shell in container:

```bash
docker exec -it --entrypoint bash CONTAINER_NAME
```
