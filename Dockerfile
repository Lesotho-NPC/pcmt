######################################################################
# Copyright (c) 2023, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

#------ php -----
FROM akeneo/pim-php-dev:6.0 AS php
ENV APP_ENV='dev'
ENV COMPOSER_HOME='/var/www/.composer'
ENV PHP_IDE_CONFIG='serverName=pim-docker-cli'
ENV XDEBUG_MODE='off'
ENV XDEBUG_CONFIG='client_host=172.17.0.1'
ENV BLACKFIRE_CLIENT_ID='client_id'
ENV BLACKFIRE_CLIENT_TOKEN='client_token'
ENV OPENID_PROVIDER_URL='https://'
ENV OPENID_CLIENT_ID='client_id'
ENV OPENID_CLIENT_SECRET='secret'
ENV OPENID_REDIRECT_URL='https://'
ENV KEYCLOAK_ADMIN='admin'
ENV KEYCLOAK_PWD='password'
ENV KEYCLOAK_REALM='master'

COPY --chown=www-data:www-data scripts /srv/pim/scripts/
COPY --chown=www-data:www-data docker /srv/pim/docker/
COPY --chown=www-data:www-data config /srv/pim/config/
COPY --chown=www-data:www-data bin /srv/pim/bin/
COPY --chown=www-data:www-data src /srv/pim/src/
COPY --chown=www-data:www-data upgrades /srv/pim/upgrades/
COPY --chown=www-data:www-data public /srv/pim/public/
COPY --chown=www-data:www-data .env /srv/pim/
COPY --chown=www-data:www-data .pcmt.env /srv/pim/
COPY --chown=www-data:www-data composer.json /srv/pim/
COPY --chown=www-data:www-data composer.lock /srv/pim/
COPY --chown=www-data:www-data docker-compose.yml /srv/pim/
COPY --chown=www-data:www-data docker-compose.tls.yml /srv/pim/
COPY --chown=www-data:www-data Makefile /srv/pim/
COPY --chown=www-data:www-data package.json /srv/pim/
COPY --chown=www-data:www-data tsconfig.json /srv/pim/
COPY --chown=www-data:www-data yarn.lock /srv/pim/
COPY --chown=www-data:www-data ecs.php /srv/pim/
COPY --chown=www-data:www-data phpunit.xml.dist /srv/pim/

WORKDIR /srv/pim

RUN php -d memory_limit=4G /usr/local/bin/composer install && \
    php -d memory_limit=4G /usr/local/bin/composer update && \
    scripts/replace-akeneo-orm-config.sh && \
    scripts/generate-env.sh && \
    rm -rf var/cache && \
    php bin/console cache:warmup && \
    rm -rf public/bundles public/js && \
    php bin/console pim:installer:assets --symlink --clean

CMD ["php"]

FROM akeneo/node:14 AS node
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

#--- fpm ----
FROM php AS fpm
ENV APP_ENV='dev'
ENV PHP_IDE_CONFIG='serverName=pim-docker-web'
ENV XDEBUG_MODE='off'
ENV XDEBUG_CONFIG='client_host=172.17.0.1'
ENV BLACKFIRE_CLIENT_ID='client_id'
ENV BLACKFIRE_CLIENT_TOKEN='client_token'
ENV BEHAT_TMPDIR='/srv/pim/var/cache/tmp'
ENV BEHAT_SCREENSHOT_PATH='/srv/pim/var/tests/screenshots'

COPY --from=node --chown=www-data:www-data /srv/pim /srv/pim
COPY --chown=root:www-data docker/fpm/logging.conf /etc/php/8.0/fpm/pool.d/logging.conf

WORKDIR /srv/pim
CMD ["php-fpm", "-F"]
VOLUME /srv/pim

#--- httpd ---
FROM httpd:2.4 AS httpd
ENV APP_ENV=dev
COPY --from=fpm --chown=root:www-data /srv/pim/docker/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY --from=fpm --chown=root:www-data /srv/pim/docker/akeneo-https.conf /usr/local/apache2/conf/vhost.conf

