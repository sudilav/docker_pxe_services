#!/bin/bash

set -e

# Support docker run --init parameter which obsoletes the use of dumb-init,
# but support dumb-init for those that still use it without --init
if [ -x "/dev/init" ]; then
    run="exec"
else
    run="exec /usr/bin/dumb-init --"
fi

#$run /usr/sbin/dhcpd -$DHCPD_PROTOCOL -f -d --no-pid $IFACE
