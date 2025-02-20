#!/bin/bash
######################################################################
# Copyright (c) 2025, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "$DIR/.."
PCMT_SEMVER=$($DIR/pcmt-semver.sh)

SSO_ENV_FILE=$DIR/../conf/".env.local"

FPM_IMAGE="pcmt/fpm:$PCMT_SEMVER"

FPM_CONTAINER_NAME=$(docker ps --filter "ancestor=$FPM_IMAGE" --format "{{.Names}}" | head -n 1)

# Check if a container is running
if [ -z "$FPM_CONTAINER_NAME" ]; then
    echo "No running container found for image: $FPM_IMAGE"
    exit 1
fi

if [ -f "$SSO_ENV_FILE" ]; then
    echo "$0 Replacing sso conf on $FPM_CONTAINER_NAME with $SSO_ENV_FILE"
    docker cp "$SSO_ENV_FILE" "$FPM_CONTAINER_NAME:/srv/pim/.env.local"
fi
