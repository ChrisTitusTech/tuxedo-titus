#!/bin/bash

set -eu

if [ ! -d /var/tmp/dkms ]; then
    mkdir -p /var/tmp/dkms
fi
