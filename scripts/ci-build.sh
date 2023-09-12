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
docker-compose exec -u www-data fpm sh -c "php -d memory_limit=4G /usr/local/bin/composer install"
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 docker-compose run -u root --rm -e YARN_REGISTRY -e PUPPETEER_SKIP_CHROMIUM_DOWNLOAD node yarn install

docker-compose exec fpm sh -c "rm -rf var/cache"
docker-compose exec -u www-data fpm sh -c "php bin/console cache:warmup"
docker-compose exec fpm sh -c "rm -rf public/bundles public/js"
docker-compose exec -u www-data fpm sh -c "scripts/replace-akeneo-orm-config.sh"
docker-compose exec -u www-data fpm sh -c "php bin/console pim:installer:assets --symlink --clean"

PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 docker-compose run -u root --rm -e YARN_REGISTRY -e PUPPETEER_SKIP_CHROMIUM_DOWNLOAD node yarn packages:build
docker-compose exec fpm sh -c "rm -rf public/dist"
docker-compose run -u root --rm -e YARN_REGISTRY -e PUPPETEER_SKIP_CHROMIUM_DOWNLOAD node yarn run webpack-dev
docker-compose exec fpm sh -c "rm -rf public/css"
docker-compose run -u root --rm -e YARN_REGISTRY -e PUPPETEER_SKIP_CHROMIUM_DOWNLOAD node yarn run less
docker-compose run -u root --rm -e YARN_REGISTRY -e PUPPETEER_SKIP_CHROMIUM_DOWNLOAD node yarn run update-extensions


docker-compose exec -u www-data fpm sh -c "php bin/console pim:installer:db --catalog vendor/pcmt/custom-dataset-bundle/src/Resources/fixtures/pcmt_global"


