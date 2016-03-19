#!/bin/bash -xe
#
# Helper script to run dhcpd against the correct interface

# IP address of interface
IP=10.254.239.1

# Get the configured interface
AWK_PRG='/^[0-9]*: / { ifs = ifs " " $2 } END { print ifs }'
IFLIST="$(ip addr list | awk -v FS='[ :]+' "$AWK_PRG")"
for intf in $IFLIST; do
    ADDR="$(ip addr show $intf | awk -v FS='[ /]*' '/^ *inet / { print $3 }')"
    if test "$ADDR" = "$IP"; then
	INTERFACE=$intf
	break
    fi
done

if test -z "$INTERFACE"; then
    echo "Interface for IP $IP not found; exiting" >&2
    exit 1
fi

exec /usr/sbin/dhcpd -q -d \
    -cf /etc/dhcp/dhcpd.conf -pf /var/run/dhcpd.pid $INTERFACE
