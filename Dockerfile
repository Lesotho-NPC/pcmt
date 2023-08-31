######################################################################
# Copyright (c) 2023, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

#------ php -----
FROM akeneo/pim-php-dev:6.0 as php
ARG HOST_COMPOSER_HOME=.cache/composer
ENV APP_ENV='prod'
ENV COMPOSER_HOME='/var/www/.composer'
ENV PHP_IDE_CONFIG='serverName=pim-docker-cli'
ENV XDEBUG_MODE='off'
ENV XDEBUG_CONFIG='client_host=172.17.0.1'
ENV BLACKFIRE_CLIENT_ID='client_id'
ENV BLACKFIRE_CLIENT_TOKEN='client_token'
USER root
ADD --chown=root:www-data $HOST_COMPOSER_HOME $COMPOSER_HOME
ADD --chown=root:www-data scripts/ /srv/pim/scripts/
ADD --chown=root:www-data docker/ /srv/pim/docker/
ADD --chown=root:www-data config/ /srv/pim/config/
ADD --chown=root:www-data .env /srv/pim/
ADD --chown=root:www-data .pcmt.env /srv/pim/
ADD --chown=root:www-data composer.json /srv/pim/
ADD --chown=root:www-data composer.lock /srv/pim/
ADD --chown=root:www-data docker-compose.yml /srv/pim/
ADD --chown=root:www-data docker-compose.tls.yml /srv/pim/
ADD --chown=root:www-data Makefile /srv/pim/
ADD --chown=root:www-data package.json /srv/pim/
ADD --chown=root:www-data tsconfig.json /srv/pim/
ADD --chown=root:www-data yarn.lock /srv/pim/

WORKDIR /srv/pim

CMD php

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
COPY --from=php --chown=root:www-data /srv/pim /srv/pim
WORKDIR /srv/pim
CMD php-fpm -F

#--- node ---
FROM akeneo/node:14 as node
ARG HOST_YARN_CACHE_FOLDER=$YARN_CACHE_FOLDER
ARG HOST_CYPRESS_CACHE_FOLDER=$CYPRESS_CACHE_FOLDER
ARG YARN_CACHE_FOLDER=/home/node/.yarn
ARG CYPRESS_CACHE_FOLDER=/home/node/.cypress
USER node
ENV YARN_CACHE_FOLDER=$YARN_CACHE_FOLDER
ENV CYPRESS_CACHE_FOLDER=$CYPRESS_CACHE_FOLDER
ADD --chown=node:node $HOST_YARN_CACHE_FOLDER $YARN_CACHE_FOLDER
ADD --chown=node:node $HOST_CYPRESS_CACHE_FOLDER $CYPRESS_CACHE_FOLDER
COPY --from=fpm --chown=node:node /srv/pim /srv/pim
WORKDIR /srv/pim

#--- httpd ---
FROM httpd:2.4 as httpd
ENV APP_ENV=prod
COPY --from=node --chown=root:www-data /srv/pim/docker/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY --from=node --chown=root:www-data /srv/pim/docker/akeneo.conf /usr/local/apache2/conf/vhost.conf

#--- pim --
FROM fpm as pim
COPY --from=node --chown=root:www-data /srv/pim /srv/pim

#---- selenium ---
FROM selenium/standalone-chrome-debug:3.141.59 as selenium
COPY --from=pim /srv/pim /srv/pim
