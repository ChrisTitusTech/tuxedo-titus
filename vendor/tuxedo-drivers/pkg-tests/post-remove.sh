#!/bin/bash

set -eu

status="$(dkms status)"

echo "$status" | grep -v "tuxedo-ibp-gen7-drivers" # Make sure dkms module is removed
