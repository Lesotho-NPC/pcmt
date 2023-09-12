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

ADD scripts /srv/pim/scripts/
ADD docker /srv/pim/docker/
ADD config /srv/pim/config/
ADD bin /srv/pim/bin/
ADD src /srv/pim/src/
ADD upgrades /srv/pim/upgrades/
ADD public /srv/pim/public/
ADD .circleci /srv/pim/.circleci/
ADD .idea /srv/pim/.idea/
ADD .cache /srv/pim/.cache/
ADD .env /srv/pim/
ADD .pcmt.env /srv/pim/
ADD composer.json /srv/pim/
ADD docker-compose.yml /srv/pim/
ADD docker-compose.tls.yml /srv/pim/
ADD Makefile /srv/pim/
ADD package.json /srv/pim/
ADD tsconfig.json /srv/pim/
ADD yarn.lock /srv/pim/

WORKDIR /srv/pim

CMD php

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

COPY --from=php --chown=www-data:www-data /srv/pim /srv/pim

WORKDIR /srv/pim
CMD php-fpm -F
VOLUME /srv/pim

#--- httpd ---
FROM httpd:2.4 as httpd
ENV APP_ENV=prod
COPY --from=fpm --chown=root:www-data /srv/pim/docker/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY --from=fpm --chown=root:www-data /srv/pim/docker/akeneo.conf /usr/local/apache2/conf/vhost.conf

