#!/bin/bash -xe
#
# Routines to help while developing

ALL_DAEMONS="dhcpd tftpd squid httpd"
IP="10.254.239.1"
RUN_DIR="/srv/docker"

# Directories to map into container; separate multiple mappings with
# spaces
declare -A VOLUMES=( \
    [tftpd]="/srv/docker/tftpd/files:/var/spool/tftp" \
    [squid]="/srv/docker/squid/debcache:/var/cache/squid-deb-proxy" \
    [httpd]="/srv/docker/httpd/root:/var/www/html" \
)

# Ports to map into container; separate multiple mappings with spaces
declare -A PORTS=( \
    [dhcpd]="67:67/udp" \
    [tftpd]="69:69/udp" \
    [squid]="8000:8000/tcp" \
    [httpd]="80:80/tcp" \
)

container_id() {
    # '-r' only returns running containers
    local RUNNING=-a
    if test "$1" = -r; then
	RUNNING=''; shift
    fi
    local NAME="$1"; test -n "$NAME" || return 0
    docker ps $RUNNING -q --filter=name=${NAME}
}

kill_container() {
    local NAME="$1"; test -n "$NAME" || return 0
    local CID=$(container_id -r $NAME); test -n "$CID" || return 0
    echo "Killing container $NAME, id $CID" >&2
    docker kill $CID
}

cleanup() {
    local NAME="$1"; test -n "$NAME" || return 0
    local CID=$(container_id $NAME); test -n "$CID" || return 0

    # Kill container, if running
    kill_container $NAME
    # Remove container
    echo "Removing container $NAME, id $CID"
    docker rm $CID
}

cleanup_all() {
    for NAME in $ALL_DAEMONS; do
	cleanup $NAME
    done
}

build() {
    docker build --tag $USER/provision .
}

volumes() {
    local NAME="$1"
    local args="--volume ${RUN_DIR}/$NAME/log:/var/log/supervisor"
    local vol
    for vol in ${VOLUMES[$NAME]}; do args+="
	--volume $vol"
    done
    echo "${args}"
}

publish() {
    local NAME="$1"
    local args
    local port
    for port in ${PORTS[$NAME]}; do args+="
	--publish ${IP}:$port"
    done
    echo "${args}"
}

create() {
    local NAME="$1"; test -n "$NAME" || return 0
    # Clean up any running container first
    cleanup $NAME
    # Create new container
    local CMD="docker create --name $NAME --hostname $NAME
	$(volumes $NAME) $(publish $NAME)
	$USER/provision"
    echo -e "creating new container with command:\n    $CMD"
    $CMD
}

start() {
    local NAME="$1"; test -n "$NAME" || return 0
    if test -n "$(container_id -r $NAME)"; then
	echo "Container $NAME already started" >&2; return
    fi
    docker start $NAME
}
