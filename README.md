# Debian PXE Provisioning System in Docker

`Dockerfile` to create a set of [Docker][docker] container images for
PXE provisioning Debian hosts.  This can run on a laptop for a
portable way of installing an OS on bare-metal hosts using an ethernet
cable and the host's PXE BIOS.

It is meant to be minimal and temporary, and thus does not focus on
security.

**Containers**:

- **DHCPD**:  a DHCP/BOOTP server for booting hosts from a PXE BIOS
- **TFTPD**:  a TFTP server for PXE boot images and configuration
- **HTTPD**:  an Apache web server for e.g. Debian installer preseed
  files
- **Squid**:  a proxy for caching Debian/Ubuntu packages, based on the
  [squid-deb-proxy][sdb] package

Containers use `supervisord` to manage services.  Application data (if
any) and logs are stored in `/srv/docker/CONTAINER_NAME`.

[docker]: https://www.docker.com/
[sdb]: https://packages.debian.org/jessie/squid-deb-proxy

- [Getting started](#getting-started)
- [DHCPD](#dhcpd)
- [TFTPD](#tftpd)
- [Squid](#squid)
- [HTTPD](#httpd)
- [Common Commands](#common-commands)
- [Developing](#developing)

## Getting started

Build the Docker image used by all containers:

```bash
git clone https://github.com/zultron/docker-provisioning.git
cd docker-provisioning
docker build --tag $USER/provision .
```

Set up an ethernet interface with IP address `10.254.239.1` in
NetworkManager:

![NetworkManager manual config][nm-img]

Now run any needed containers as in the following sections.

[nm-img]: common/nm-manual-config.png

## DHCPD

Create the container; this must be run with the host's network
attached:

```bash
docker create --name dhcpd --net=host --env=CMD=dhcpd \
	--volume /srv/docker/dhcpd/log:/var/log/supervisor \
	--volume /srv/docker/dhcpd/var:/var/lib/dhcp \
	$USER/provision
```

Start the container.

## TFTPD

Set up an interface with an IP address and create the container:

```bash
docker create --name tftpd --hostname tftpd \
	--volume /srv/docker/tftpd/log:/var/log/supervisor \
	--volume /srv/docker/tftpd/files:/var/spool/tftp \
	--publish 10.254.239.1:69:69/udp $USER/provision
```

Now start the container and unpack the Debian `netboot.tar.gz` files
into `/srv/docker/tftpd/files`, as appropriate.

## Squid

Create the cache directory and the container:

```bash
mkdir -p /srv/docker/squid/debcache
docker create --name squid --hostname squid --publish 8000:8000 \
	--volume /srv/docker/squid/debcache:/var/cache/squid-deb-proxy \
	--volume /srv/docker/squid/log:/var/log/supervisor \
	$USER/provision
```

Start the container.  The proxy may be used from the installer as
`http://10.254.239.1:8000`, and from APT by creating a file in
`/etc/apt/apt.conf.d/01proxy` with these contents:

```
Acquire::http::Proxy "http://10.254.239.1:8000";
```

## HTTPD

Create the container:

```bash
docker create --name httpd --hostname httpd --publish 80:80 \
	--volume /srv/docker/httpd/root:/var/www/html \
	--volume /srv/docker/httpd/log:/var/log/supervisor \
	$USER/provision
```

Now start the container and place files in `/srv/docker/httpd/root`,
as appropriate.

## Common Commands

In the following commands, common to all containers, replace
`CONTAINER_NAME` with `squid`, `dhcpd`, `tftpd`, etc.

Start a container:

```bash
docker start CONTAINER_NAME
```

Start a shell in a container:

```bash
docker exec -it --entrypoint bash CONTAINER_NAME
```

## Developing

Some handy commands for developers are in `common/dev-routines.sh`.
To use them:

```bash
. common/dev-routines.sh
prov_help
```

## TODO

- Orchestration
- Can DHCPD run in regular network mode?  Perhaps by publishing with
  the broadcast address?  But then it must be restricted to the
  intended ethernet interface.

