#!/bin/bash

set -e


# Support docker run --init parameter which obsoletes the use of dumb-init,
# but support dumb-init for those that still use it without --init
if [ -x "/dev/init" ]; then
    run="exec"
else
    run="exec /usr/bin/dumb-init --"
fi

# Single argument to command line is interface name
if [ $# -eq 1 -a -n "$1" ]; then
    # skip wait-for-interface behavior if found in path
    if ! which "$1" >/dev/null; then
        # loop until interface is found, or we give up
        NEXT_WAIT_TIME=1
        until [ -e "/sys/class/net/$1" ] || [ $NEXT_WAIT_TIME -eq 4 ]; do
            sleep $(( NEXT_WAIT_TIME++ ))
            echo "Waiting for interface '$1' to become available... ${NEXT_WAIT_TIME}"
        done
        if [ -e "/sys/class/net/$1" ]; then
            IFACE="$1"
        fi
    fi
fi

# No arguments mean all interfaces
if [ -z "$1" ]; then
    IFACE=" "
fi

if [ -n "$IFACE" ]; then
    # Run dhcpd for specified interface or all interfaces

    $run /usr/sbin/dhcpd -$DHCPD_PROTOCOL -f -d --no-pid $IFACE
else
    # Run another binary
    $run "$@"
fi
