#!/bin/bash
######################################################################
# Copyright (c) 2023, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

# Path of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

PCMT_VER=$($DIR/pcmt-ver-sha.sh)

cd "$DIR/.."

echo "$0 install dependencies..."
docker-compose -f docker-compose.dev.yml run -u www-data --rm php php -d memory_limit=4G /usr/local/bin/composer install

echo "$0 Lint check for $PCMT_VER..."
docker-compose -f docker-compose.dev.yml run -u www-data --rm php php /srv/pim/vendor/bin/ecs check src

# Run tests
echo "Running php unit Tests..."

XDEBUG_MODE=coverage docker-compose -f docker-compose.dev.yml run -u www-data --rm php php vendor/bin/phpunit \
    --log-junit ./build/unit-results.xml \
    --coverage-clover ./build/coverage.xml \
    --coverage-html ./build/coverage-report \
    --coverage-text \
    --colors=never
status=$?

# Check if the tests failed
if [ $status -ne 0 ]; then
  echo "Tests failed with exit code $status"
  exit $status
fi

echo "Tests completed."