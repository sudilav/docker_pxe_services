#!/bin/bash

# First let's perform the check that we have everything needed:
# docker
# modprobe for the necessary nfs modules needed by the kernel
# And that our interfaces is setup correctly

source ./check.sh

./setup.sh
