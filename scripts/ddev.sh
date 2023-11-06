#!/bin/bash
######################################################################
# Copyright (c) 2023, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

# Path of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

PCMT_VER=$($DIR/pcmt-ver-sha.sh)

PCMT_VER=$PCMT_VER docker-compose -f docker-compose.yml \
    ${@}