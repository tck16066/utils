#!/bin/bash

#
# This file is not copyrighted.
#

if [ "$(id | awk '{split($1, a, "="); split(a[2], b, "("); print b[1]}')" -ne "0" ]; then
    echo "script must be run as root."
    exit -1
fi


if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "We are chrooted!"
else
  echo "NOT chroot"
fi
