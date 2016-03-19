#!/bin/bash -e

if test -z "$CMD"; then
    if test -n "$1"; then
	CMD="$1"
    else
	CMD="$(hostname)"
    fi
fi

SVD="/usr/bin/supervisord"
SVD_CONF="/etc/supervisor/conf.d/$CMD.conf"
SVD_OPTS="-nc $SVD_CONF"
INIT_SCRIPT="/etc/provisioning/$CMD.init.sh"

if ! test -f "$SVD_CONF"; then
    echo "Unknown command; exiting" >&2; exit 1
fi

if test -f "$INIT_SCRIPT"; then
    # Found an init script; run it
    bash -xe $INIT_SCRIPT
fi

$SVD $SVD_OPTS
