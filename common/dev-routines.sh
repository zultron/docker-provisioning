#!/bin/bash -xe
#
# Routines to help while developing

ALL_DAEMONS="dhcpd tftpd squid httpd"
IP="10.254.239.1"
RUN_DIR="/srv/docker"

# Directories to map into container; separate multiple mappings with
# spaces
declare -A VOLUMES=( \
    [dhcpd]="/srv/docker/dhcpd/var:/var/lib/dhcp" \
    [tftpd]="/srv/docker/tftpd/files:/var/spool/tftp" \
    [squid]="/srv/docker/squid/debcache:/var/cache/squid-deb-proxy" \
    [httpd]="/srv/docker/httpd/root:/var/www/html" \
)

# Ports to map into container; separate multiple mappings with spaces;
# if the special value "host", then the container will be configured
# with '--net=host'
declare -A PORTS=( \
    [dhcpd]="host" \
    [tftpd]="69:69/udp" \
    [squid]="8000:8000/tcp" \
    [httpd]="80:80/tcp" \
)

prov_container_id() {
    # '-r' only returns running containers
    local RUNNING=-a
    if test "$1" = -r; then
	RUNNING=''; shift
    fi
    local NAME="$1"; test -n "$NAME" || return 0
    docker ps $RUNNING -q --filter=name=${NAME}
}

prov_kill() {
    local NAME="$1"; test -n "$NAME" || return 0
    local CID=$(prov_container_id -r $NAME); test -n "$CID" || return 0
    echo "Killing container $NAME, id $CID" >&2
    docker kill $CID
}

prov_kill_all() {
    for NAME in $ALL_DAEMONS; do
	prov_kill $NAME
    done
}

prov_cleanup() {
    local NAME="$1"; test -n "$NAME" || return 0
    local CID=$(prov_container_id $NAME); test -n "$CID" || return 0

    # Kill container, if running
    prov_kill $NAME
    # Remove container
    echo "Removing container $NAME, id $CID" >&2
    docker rm $CID
}

prov_cleanup_all() {
    for NAME in $ALL_DAEMONS; do
	prov_cleanup $NAME
    done
}

prov_build() {
    docker build --tag $USER/provision .
}

prov_volumes() {
    local NAME="$1"
    local args="--volume ${RUN_DIR}/$NAME/log:/var/log/supervisor"
    local vol
    for vol in ${VOLUMES[$NAME]}; do args+="
	--volume $vol"
    done
    echo "${args}"
}

prov_publish() {
    local NAME="$1"
    if test "${PORTS[$NAME]}" = "host"; then
	# Special case:  attach host network to container
	echo "--net=host"
	return
    fi

    local args="--hostname=$NAME"
    local port
    for port in ${PORTS[$NAME]}; do args+="
	--publish ${IP}:$port"
    done
    echo "${args}"
}

prov_create() {
    local NAME="$1"; test -n "$NAME" || return 0
    # Clean up any running container first
    prov_cleanup $NAME
    # Create new container
    local CMD="docker create --name $NAME
	--env=CMD=$NAME
	$(prov_publish $NAME)
	$(prov_volumes $NAME)
	$USER/provision"
    echo -e "Creating new container $NAME:\n    $CMD" >&2
    $CMD
}

prov_create_all() {
    for NAME in $ALL_DAEMONS; do
	prov_create $NAME
    done
}

prov_start() {
    local NAME="$1"; test -n "$NAME" || return 0
    if test -n "$(prov_container_id -r $NAME)"; then
	echo "Container $NAME already started" >&2; return
    fi
    docker start $NAME
}

prov_start_all() {
    for NAME in $ALL_DAEMONS; do
	prov_start $NAME
    done
}

prov_help() {
    {
	# Spaces added to mimic tabs when printed
	echo   "Provisioning commands:"
	echo   "  prov_build		build Docker image"
	echo   "  prov_create NAME	create Docker container NAME"
	echo   "  prov_create_all	create all Docker containers"
	echo   "  prov_start NAME	start Docker container NAME"
	echo   "  prov_start_all	start all Docker containers"
	echo   "  prov_kill NAME	kill Docker container NAME"
	echo   "  prov_kill_all		kill all Docker containers"
	echo   "  prov_cleanup NAME	kill and remove Docker container NAME"
	echo   "  prov_cleanup_all	kill and remove all Docker containers"
    } >&2
}
