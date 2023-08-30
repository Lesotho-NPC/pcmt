#!/bin/bash
######################################################################
# Copyright (c) 2019, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

PIM_CONTAINER=pcmt_build_pim
NODE_CONTAINER=pcmt_build_node

function cleanup {
    echo "Cleaning up container"
    docker rm $PIM_CONTAINER
    docker rm $NODE_CONTAINER
}
trap cleanup EXIT


# Path of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# path of .env file
ENV_PATH="$DIR/../.pcmt.env"

# path to cache - local and container
COMPOSER_CACHE_LOCAL_PATH="$DIR/../.cache/composer"
COMPOSER_CACHE_PATH="/var/www/.composer"
YARN_CACHE_LOCAL_PATH="$DIR/../.cache/yarn-cache"
YARN_CACHE_PATH="/home/node/.yarn"

# Load .env file and PCMT_VER, in format for env
DOT_ENV=$(grep -viE '^(PCMT_VER|#)' $ENV_PATH | xargs) 
PCMT_SEMVER=$("$DIR/pcmt-semver.sh")
PCMT_VER=$("$DIR/pcmt-ver-sha.sh")
BUILD_ENV="$DOT_ENV PCMT_VER=$PCMT_VER"

# prep local cache directories
mkdir -p $COMPOSER_CACHE_LOCAL_PATH
mkdir -p $YARN_CACHE_LOCAL_PATH

# build all targets
env $BUILD_ENV docker-compose -f "$DIR/../docker-compose.yml" build \
    --force-rm \
    --build-arg COMPOSER_HOME=${COMPOSER_CACHE_PATH} \
    --build-arg PCMT_SEMVER=${PCMT_SEMVER}

# copy the composer cache to local
docker create --name $PIM_CONTAINER pcmt/pcmt:${PCMT_VER}
docker cp $PIM_CONTAINER:$COMPOSER_CACHE_PATH/. $COMPOSER_CACHE_LOCAL_PATH

# copy the yarn cache to local
docker create --name $NODE_CONTAINER pcmt/node:${PCMT_VER}
docker cp $NODE_CONTAINER:$YARN_CACHE_PATH/. $YARN_CACHE_LOCAL_PATH
