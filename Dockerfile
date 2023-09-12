######################################################################
# Copyright (c) 2023, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

#------ php -----
FROM akeneo/pim-php-dev:6.0 as php
ENV APP_ENV='dev'
ENV COMPOSER_HOME='/var/www/.composer'
ENV PHP_IDE_CONFIG='serverName=pim-docker-cli'
ENV XDEBUG_MODE='off'
ENV XDEBUG_CONFIG='client_host=172.17.0.1'
ENV BLACKFIRE_CLIENT_ID='client_id'
ENV BLACKFIRE_CLIENT_TOKEN='client_token'

COPY scripts /srv/pim/scripts/
COPY docker /srv/pim/docker/
COPY config /srv/pim/config/
COPY bin /srv/pim/bin/
COPY src /srv/pim/src/
COPY upgrades /srv/pim/upgrades/
COPY public /srv/pim/public/
COPY .circleci /srv/pim/.circleci/
COPY .idea /srv/pim/.idea/
COPY .cache /srv/pim/.cache/
COPY .env /srv/pim/
COPY .pcmt.env /srv/pim/
COPY composer.json /srv/pim/
COPY docker-compose.yml /srv/pim/
COPY docker-compose.tls.yml /srv/pim/
COPY Makefile /srv/pim/
COPY package.json /srv/pim/
COPY tsconfig.json /srv/pim/
COPY yarn.lock /srv/pim/

WORKDIR /srv/pim

RUN php -d memory_limit=4G /usr/local/bin/composer install && \
    scripts/replace-akeneo-orm-config.sh && \
    rm -rf var/cache && \
    php bin/console cache:warmup && \
    rm -rf public/bundles public/js && \
    php bin/console pim:installer:assets --symlink --clean

CMD php

VOLUME /srv/pim

FROM akeneo/node:14 as node
ENV YARN_CACHE_FOLDER=/home/node/.yarn
ENV CYPRESS_CACHE_FOLDER=/home/node/.cypress
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
COPY --from=php --chown=node:node /srv/pim /srv/pim

WORKDIR /srv/pim

RUN yarn install && \
    yarn packages:build && \
    rm -rf public/dist && \
    yarn run webpack-dev && \
    rm -rf public/css && \
    yarn run less && \
    yarn run update-extensions

VOLUME /srv/pim

#--- fpm ----
FROM php as fpm
ENV APP_ENV='dev'
ENV PHP_IDE_CONFIG='serverName=pim-docker-web'
ENV XDEBUG_MODE='off'
ENV XDEBUG_CONFIG='client_host=172.17.0.1'
ENV BLACKFIRE_CLIENT_ID='client_id'
ENV BLACKFIRE_CLIENT_TOKEN='client_token'
ENV BEHAT_TMPDIR='/srv/pim/var/cache/tmp'
ENV BEHAT_SCREENSHOT_PATH='/srv/pim/var/tests/screenshots'

COPY --from=node --chown=www-data:www-data /srv/pim /srv/pim

WORKDIR /srv/pim
CMD php-fpm -F
VOLUME /srv/pim

#--- httpd ---
FROM httpd:2.4 as httpd
ENV APP_ENV=dev
COPY --from=fpm --chown=root:www-data /srv/pim/docker/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY --from=fpm --chown=root:www-data /srv/pim/docker/akeneo.conf /usr/local/apache2/conf/vhost.conf

