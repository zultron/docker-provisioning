#!/bin/bash -e

if test -n "$1"; then
    CMD="$1"
else
    CMD="$(hostname)"
fi


SVD="/usr/bin/supervisord"
SVD_CONF="/etc/supervisor/conf.d/$CMD.conf"
SVD_OPTS="-nc $SVD_CONF"

if ! test -f "$SVD_CONF"; then
    echo "Unknown command; exiting" >&2; exit 1
fi

$SVD $SVD_OPTS
