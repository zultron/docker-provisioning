#!/bin/bash -xe
#
# First-time init for dhcpd

# Remove any stale lock file
rm -f /run/dhcpd.pid

# Create the leases file
touch /var/lib/dhcp/dhcpd.leases
