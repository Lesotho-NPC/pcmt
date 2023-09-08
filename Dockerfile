######################################################################
# Copyright (c) 2023, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

#------ php -----
FROM akeneo/pim-php-dev:6.0 as php
ENV APP_ENV='prod'
ENV COMPOSER_HOME='/var/www/.composer'
ENV PHP_IDE_CONFIG='serverName=pim-docker-cli'
ENV XDEBUG_MODE='off'
ENV XDEBUG_CONFIG='client_host=172.17.0.1'
ENV BLACKFIRE_CLIENT_ID='client_id'
ENV BLACKFIRE_CLIENT_TOKEN='client_token'
USER root
ADD --chown=www-data:www-data scripts /srv/pim/scripts/
ADD --chown=www-data:www-data docker /srv/pim/docker/
ADD --chown=www-data:www-data config /srv/pim/config/
ADD --chown=www-data:www-data bin /srv/pim/bin/
ADD --chown=www-data:www-data src /srv/pim/src/
ADD --chown=www-data:www-data upgrades /srv/pim/upgrades/
ADD --chown=www-data:www-data public /srv/pim/public/
ADD --chown=www-data:www-data var /srv/pim/var/
ADD --chown=www-data:www-data .circleci /srv/pim/.circleci/
ADD --chown=www-data:www-data .idea /srv/pim/.idea/
ADD --chown=www-data:www-data .cache /srv/pim/.cache/
ADD --chown=www-data:www-data .env /srv/pim/
ADD --chown=www-data:www-data .pcmt.env /srv/pim/
ADD --chown=www-data:www-data composer.json /srv/pim/
ADD --chown=www-data:www-data docker-compose.yml /srv/pim/
ADD --chown=www-data:www-data docker-compose.tls.yml /srv/pim/
ADD --chown=www-data:www-data Makefile /srv/pim/
ADD --chown=www-data:www-data package.json /srv/pim/
ADD --chown=www-data:www-data tsconfig.json /srv/pim/

WORKDIR /srv/pim

RUN php -d memory_limit=4G /usr/local/bin/composer install && \
    scripts/replace-akeneo-orm-config.sh && \
    rm -rf var/cache && \
    php bin/console cache:warmup && \
    rm -rf public/bundles public/js && \
    php bin/console pim:installer:assets --symlink --clean

CMD php

VOLUME /srv/pim

#--- node ---
FROM akeneo/node:14 as node
ENV YARN_CACHE_FOLDER='/home/node/.yarn'
ENV CYPRESS_CACHE_FOLDER='/home/node/.cypress'
USER node
COPY --from=php --chown=node:node /srv/pim /srv/pim
WORKDIR /srv/pim

RUN PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 yarn packages:build && \
    rm -rf public/dist && \
    yarn run webpack-dev && \
    rm -rf public/css && \
    yarn run less && \
    yarn run update-extensions

VOLUME /srv/pim


#--- fpm ----
FROM php as fpm
ENV APP_ENV='prod'
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
ENV APP_ENV=prod
COPY --from=fpm --chown=root:www-data /srv/pim/docker/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY --from=fpm --chown=root:www-data /srv/pim/docker/akeneo.conf /usr/local/apache2/conf/vhost.conf

