#!/bin/bash
######################################################################
# Copyright (c) 2019, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "$DIR/.."
docker-compose build
APP_ENV=dev docker-compose up -d
docker/wait_docker_up.sh
docker-compose exec -u www-data fpm sh -c "php bin/console pim:installer:db --catalog vendor/pcmt/custom-dataset-bundle/src/Resources/fixtures/pcmt_global"


