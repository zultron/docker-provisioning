#!/bin/bash
set -ex

CMD="$1"

case "$CMD" in
    squid) /etc/init.d/squid-deb-proxy start ;;
esac
