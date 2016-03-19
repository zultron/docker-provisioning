# Debian Provisioning System in Docker

- [Introduction](#introduction)
- [Getting started](#getting-started)
- [Squid](#squid)
- [DHCPD](#dhcpd)
- [TFTPD](#tftpd)
- [Common Commands](#common-commands)

## Introduction

`Dockerfile` to create a set of [Docker](https://www.docker.com/)
container images for provisioning Debian hosts.

Containers:

- DHCPD:  a DHCP/BOOTP server for booting hosts from a PXE BIOS
- TFTPD:  a TFTP server for PXE boot images and configuration
- HTTPD:  (not yet implemented) a web server for Debian installer
  preseed files
- Squid:  a proxy for caching Debian/Ubuntu packages, based on the
  [squid-deb-proxy][sdb] package

[sdb]: https://packages.debian.org/jessie/squid-deb-proxy

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

## TFTPD

Set up an interface with an IP address and create the container:

```bash
sudo ifconfig eth0 10.254.239.1 netmask 255.255.255.0
docker create --name tftpd --hostname tftpd \
	--volume /srv/docker/tftpd/log:/var/log/supervisor \
	--volume /srv/docker/tftpd/files:/var/spool/tftp \
	--publish 10.254.239.1:69:69/udp $USER/provision
```

Now start the container and unpack the Debian `netboot.tar.gz` files
into `/srv/docker/tftpd/files`, as appropriate.

## Common Commands

Start a container; replace `CONTAINER_NAME` with `squid`, `dhcpd`,
`tftpd`, etc.:

```bash
docker start CONTAINER_NAME
```

Start a shell in a container:

```bash
docker exec -it --entrypoint bash CONTAINER_NAME
```
