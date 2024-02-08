#
# This file is a template Makefile. Some targets are presented here as examples.
# Feel free to customize it to your needs!
#
CMD_ON_PROJECT = docker-compose -f docker-compose.dev.yml run -u www-data --rm php
PHP_RUN = $(CMD_ON_PROJECT) php
YARN_RUN = docker-compose -f docker-compose.dev.yml run -u node --rm -e YARN_REGISTRY -e PUPPETEER_SKIP_CHROMIUM_DOWNLOAD node yarn
PCMT_CMD_ON_PROJECT = docker-compose exec -u www-data fpm
PCMT_PHP_RUN = $(PCMT_CMD_ON_PROJECT) php

ifdef NO_DOCKER
  CMD_ON_PROJECT =
  YARN_RUN = yarnpkg
  PHP_RUN = php
endif

.DEFAULT_GOAL := dev

yarn.lock: package.json
	PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 $(YARN_RUN) install

node_modules: yarn.lock
	PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 $(YARN_RUN) install

.PHONY: javascript-extensions
javascript-extensions:
	$(YARN_RUN) run update-extensions

.PHONY: front-packages
front-packages:
	PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 $(YARN_RUN) packages:build

.PHONY: assets
assets:
	$(CMD_ON_PROJECT) rm -rf public/bundles public/js
	$(PHP_RUN) bin/console pim:installer:assets --symlink --clean

.PHONY: css
css:
	$(CMD_ON_PROJECT) rm -rf public/css
	$(YARN_RUN) run less

.PHONY: javascript-prod
javascript-prod:
	$(CMD_ON_PROJECT) rm -rf public/dist
	$(YARN_RUN) run webpack

.PHONY: javascript-dev
javascript-dev:
	$(CMD_ON_PROJECT) rm -rf public/dist
	$(YARN_RUN) run webpack-dev

.PHONY: front
front: assets css front-packages javascript-dev

.PHONY: database
database:
	$(PHP_RUN) bin/console pim:installer:db ${O}

.PHONY: cache
cache:
	$(CMD_ON_PROJECT) rm -rf var/cache && $(PHP_RUN) bin/console cache:warmup

composer.lock: composer.json
	$(PHP_RUN) -d memory_limit=4G /usr/local/bin/composer update

vendor: composer.lock
	$(PHP_RUN) -d memory_limit=4G /usr/local/bin/composer install

.PHONY: dependencies
dependencies: vendor node_modules

.PHONY: dev
dev:
	$(MAKE) dependencies
	$(MAKE) pim-dev

.PHONY: prod
prod:
	$(MAKE) dependencies
	$(MAKE) pim-prod

.PHONY: pim-prod
pim-prod:
ifndef NO_DOCKER
	APP_ENV=prod $(MAKE) up
	docker/wait_docker_up.sh
endif
	$(MAKE) cache
	$(MAKE) assets
	$(MAKE) front-packages
	$(MAKE) javascript-prod
	$(MAKE) css
	$(MAKE) javascript-extensions
	$(MAKE) replace-orm-configs
	APP_ENV=prod $(MAKE) database O="--catalog vendor/akeneo/pim-community-dev/src/Akeneo/Platform/Bundle/InstallerBundle/Resources/fixtures/minimal"

.PHONY: pim-dev
pim-dev:
ifndef NO_DOCKER
	APP_ENV=dev $(MAKE) up
	docker/wait_docker_up.sh
endif
	$(MAKE) cache
	$(MAKE) assets
	$(MAKE) front-packages
	$(MAKE) javascript-dev
	$(MAKE) css
	$(MAKE) javascript-extensions
	$(MAKE) replace-orm-configs
	APP_ENV=dev $(MAKE) database O="--catalog vendor/pcmt/custom-dataset-bundle/src/Resources/fixtures/pcmt_global"

.PHONY: up
up:
	docker-compose -f docker-compose.dev.yml up -d --remove-orphans

.PHONY: down
down:
	docker-compose -f docker-compose.dev.yml down -v

.PHONY: upgrade-front
upgrade-front:
	$(MAKE) node_modules
	$(MAKE) cache
	$(MAKE) assets
	$(MAKE) front-packages
	$(MAKE) javascript-prod
	$(MAKE) css
	$(MAKE) javascript-extensions

.PHONY: replace-orm-configs
replace-orm-configs:
	./scripts/replace-akeneo-orm-config.sh

.PHONY: start-job-queue
start-job-queue:
	docker-compose exec -T -d fpm php bin/console messenger:consume ui_job import_export_job data_maintenance_job ${O}

.PHONY: terraform
terraform:
	cd deploy/terraform && ./build.sh

.PHONY: ansible
ansible:
	cd deploy/ansible && ./build.sh

.PHONY: pcmt-build
pcmt-build:
	docker-compose build --force-rm

.PHONY: pcmt-down
pcmt-down:
	docker-compose down -v --remove-orphans

.PHONY: pcmt-prod
pcmt-prod:
ifndef NO_DOCKER
	APP_ENV=prod $(MAKE) pcmt-up
	docker/wait_docker_up.sh
endif
	APP_ENV=prod $(MAKE) pcmt-database O="--catalog vendor/akeneo/pim-community-dev/src/Akeneo/Platform/Bundle/InstallerBundle/Resources/fixtures/minimal"
	$(MAKE) start-job-queue 0="--env=prod"

.PHONY: pcmt-dev
pcmt-dev:
ifndef NO_DOCKER
	APP_ENV=dev $(MAKE) pcmt-up
	docker/wait_docker_up.sh
endif
	APP_ENV=dev $(MAKE) pcmt-database O="--catalog vendor/pcmt/custom-dataset-bundle/src/Resources/fixtures/pcmt_global"
	$(MAKE) start-job-queue 0="--env=dev"

.PHONY: pcmt-up
pcmt-up:
	docker-compose up -d --no-build --remove-orphans

.PHONY: pcmt-pull
pcmt-pull:
	docker-compose pull

.PHONY: pcmt-versha-build
pcmt-versha-build:
	./scripts/ddev.sh build --force-rm

.PHONY: cron
cron:
	cd deploy/cron && docker build -t pcmt/cron:3.0.0-snapshot .

.PHONY: asset-backup
asset-backup: cron
	cd deploy/asset-backup && docker build -t pcmt/asset-backup:3.0.0-snapshot .

.PHONY: mysql-backup
mysql-backup: cron
	cd deploy/mysql-backup && docker build -t pcmt/mysql-backup:3.0.0-snapshot .

.PHONY: s3
s3: cron
	cd deploy/s3 && docker build -t pcmt/s3:3.0.0-snapshot .

.PHONY: scp-put
scp-put: cron
	cd deploy/scp-put && docker build -t pcmt/scp-put:3.0.0-snapshot .

.PHONY: ftp-get
ftp-get: cron
	cd deploy/ftp-get && docker build -t pcmt/ftp-get:3.0.0-snapshot .

.PHONY: ftp-put
ftp-put: cron
	cd deploy/ftp-put && docker build -t pcmt/ftp-put:3.0.0-snapshot .

.PHONY: scalyr
scalyr:
	cd deploy/scalyr && docker build -t pcmt/scalyr:3.0.0-snapshot .

.PHONY: pcmt-cache
pcmt-cache:
	docker-compose exec fpm rm -rf var/cache && $(PCMT_PHP_RUN) bin/console cache:warmup

.PHONY: migrate
migrate:
	$(PCMT_PHP_RUN) bin/console --no-interaction doctrine:migrations:migrate

.PHONY: schema-update
schema-update:
	$(PCMT_PHP_RUN) bin/console doctrine:schema:update --force

.PHONY: reset-indexes
reset-indexes:
	$(PCMT_PHP_RUN) bin/console --no-interaction akeneo:elasticsearch:reset-indexes --index=akeneo_pim_product_and_product_model

.PHONY: product-model-index
product-model-index:
	$(PCMT_PHP_RUN) bin/console pim:product-model:index --all

.PHONY: product-index
product-index:
	$(PCMT_PHP_RUN) bin/console pim:product:index --all

.PHONY: cache-clear
cache-clear:
	$(PCMT_PHP_RUN) bin/console cache:clear

.PHONY: migrate-pcmt2-db
migrate-pcmt2-db:
	scripts/pcmt2-db-migration.sh

.PHONY: update-fpm-folder-user
update-fpm-folder-user:
	docker-compose exec fpm chown -R www-data:www-data /srv/pim && $(MAKE) cache-clear

.PHONY: pcmt-database
pcmt-database:
	$(PCMT_PHP_RUN) bin/console pim:installer:db ${O}
