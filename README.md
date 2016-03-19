# Debian Provisioning System in Docker

- [Introduction](#introduction)
- [Getting started](#getting-started)
- [Usage](#usage)
- [Shell Access](#shell-access)

## Introduction

`Dockerfile` to create a [Docker](https://www.docker.com/) container
image for provisioning Debian.

This is a WIP.

Pieces in place:

- Squid:  a caching proxy for Debian/Ubuntu packages, based on
[squid-deb-proxy][sdb]

[sdb]: https://packages.debian.org/jessie/squid-deb-proxy

Pieces planned:

- DHCP/BOOTP server for booting new hosts from BIOS
- TFTP server for downloading kernels and install images
- HTTP server for serving preseed files
- (Possibly) BCFG2 server for post-install host configuration

## Getting started

Build the image:

```bash
git clone https://github.com/zultron/docker-squid.git
cd docker-squid
docker build --tag $USER/squid .
```

Create the cache directory:

```bash
mkdir -p /srv/docker/squid/debcache
```

Start Squid using:

```bash
docker run --name squid -t --rm --publish 8000:8000 \
  --volume /srv/docker/squid/debcache:/var/cache/squid-deb-proxy \
  $USER/squid
```

Start shell in container:

```bash
docker start -it squid bash -i
```

## Usage

Create a file in `/etc/apt/apt.conf.d/01proxy` with these contents:

```
Acquire::http::Proxy "http://localhost:8000";
```
