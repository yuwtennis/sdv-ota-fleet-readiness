#!/usr/bin/bash

HOST_NAME=vehicle

virsh destroy $HOST_NAME 2>/dev/null
virsh undefine $HOST_NAME --nvram --remove-all-storage