#!/bin/bash
######################################################################
# Copyright (c) 2020, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

if [ -z "$PCMT_HOSTNAME" ]; then
    echo "Error env PCMT_HOSTNAME not present"
    exit 1
fi

: "${PCMT_SCALYR_CREDS_CONF:=/run/secrets/scalyr-creds}"
if [ ! -r "$PCMT_SCALYR_CREDS_CONF" ]; then
    echo "$PCMT_SCALYR_CREDS_CONF is not readable"
    exit 1
fi
ln -s "$PCMT_SCALYR_CREDS_CONF" "/etc/scalyr-agent-2/agent.d/api_key.json"


/usr/sbin/scalyr-agent-2 --no-fork --no-change-user start 2>&1