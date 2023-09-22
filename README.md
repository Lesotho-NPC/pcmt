# Product Catalog Management Tool (PCMT)

PCMT helps organizations tame their multitudes of Product definitions,
Catalogs, and coding schemes that exist when a collaboration of many groups
are procuring, using and sharing product data.

More specifically the PCMT is aimed at global health stakeholders to ease
their interoperability and master data challenges.

## License, Copyright, Conduct and Contribution

PCMT is an open and freely available community project stewarded by
VillageReach.  PCMT code and documentation is copyright VillageReach and
licensed under the [NP-OSL v3][np-osl] and the [CC BY-SA 4.0][cc-by-sa].

- [PCMT License & Copyright][pcmt-license]
- [Architecture Decision](./doc/arch/adr-006.md)
- [License How-to](./doc/license-howto.md)
- [Code of Conduct](https://www.contributor-covenant.org/version/1/4/code-of-conduct/)
- TODO: Contribution guide

PCMT includes a derivative work of Akeneo PIM Community Edition which is
copyrighted and licensed from Akeneo SAS:

- [Akeneo PIM CE License & Copyright][akeneo-license]
- [Akeneo PIM Source Code][akeneo-source]

[np-osl]: https://opensource.org/licenses/NPOSL-3.0
[cc-by-sa]: https://creativecommons.org/licenses/by-sa/4.0/
[pcmt-license]: ./COPYRIGHT.md
[akeneo-license]: https://github.com/akeneo/pim-community-standard/blob/master/LICENCE.txt
[akeneo-source]: https://github.com/akeneo/pim-community-standard

## Quick Start

1. Clone Repository
1. `make pcmt-pull`
2. `make pim-prod`
1. Browse to `localhost:8080`
1. Login with `admin` / `Admin123`.

To stop & cleanup:  `make pcmt-down`.

## Development

1. Clone Repository
2. `make pcmt-build`
1. `make pim-dev` to run containers.
1. Wait for environment to start
1. Browse to `localhost:8080`
1. Login with `admin` / `Admin123`.


### Commands

PCMT adds a number of commands that a developer may use.  Unless otherwise
noted these commands are meant to be run in the `fpm`
service.

Example:

```shell
docker-compose exec -u www-data fpm bash
bin/console <command>
```

### Configuration

PCMT secrets are primarly configured through
configuration files found in the `conf/` directory and `.pcmt.env` file.

MySQL and ElasticSearch are both configured through their respective docker
container defaults, for now.

#### SSL

The `reverse-proxy` container is responsible for TLS termination using
[Traefik][traefik].  This repository includes a
dynamic configuration that is based on the docker provider, a default
configuration is included in [docker-compose.tls.yml](docker-compose.tls.yml).

The default configuration could be used by:

```shell
PCMT_PROFILE=dev docker-compose \
    up -d --remove-orphans
```
Edit [Dockerfile](Dockerfile)
    - For service httpd change `/srv/pim/docker/akeneo.conf` to `/srv/pim/docker/akeneo-https.conf`
        -This will ensure https redirect for the project
It's recommended that:
- Edit [docker-compose.tls.yml](docker-compose.tls.yml)
    - Set the `email` field to a valid email.
    - Remove the line `caServer = "https://acme-staging-v02.api.letsencrypt.org/directory"`.
- Set a publicly available hostname with `PCMT_HOSTNAME` when launching, e.g.
  `PCMT_HOSTNAME=pcmt.villagereach.org docker-compose -f docker-compose.yml -f docker-compose.tls.yml up`
  as this will be used to get a certificate with [LetsEncrypt][letsencrypt].

Note that if you re-launch and change `PCMT_HOSTNAME` that you may need to
remove the existing certs in the docker volume `traefikdata`.

[traefik]: https://docs.traefik.io
[letsencrypt]: https://letsencrypt.org

#### Reference Data

`bin/console pcmt:handler:download_reference_data` - Downloads the latest  
reference data from the Internet and stores them alongside the source code.
Run this to update these codes and commit to source control.

`bin/console pcmt:handler:import_reference_data` - Imports the reference data
downloaded in the previous command into the database, potentially overwriting  
any referencedata already there.  Use this in development or testing contexts  
so that the reference data is available in the UI, but beware of running this  
in production.

---
Copyright (c) 2023, VillageReach.  Licensed CC BY-SA 4.0:  https://creativecommons.org/licenses/by-sa/4.0/

## Production

This section covers the additional services added with `docker-compose.tls.yml`.

### Production Profile

The `production` profile ensures that PCMT doesn't wipe and re-install the
demo-data in the database - which is the default behavior.

To set this profile set the environment variable `APP_ENV` to `prod`
before starting PCMT.

An example of start PCMT with the demo data, stopping it, and then starting
with the `prod` profile would look roughly like this (with a bash shell):

Edit [Dockerfilw](Dockerfile) service node `yarn run webpack-dev` to ` yarn run webpack`
```shell
# start in dev profile to get demo-data and initial db config
make pcmt-build
make pcmt-dev

#  wait for PCMT to start in your browser

# stop with the demo data, and re-start in production.
make pcmt-down
make pcmt-build
make pcmt-prod
```

This example is meant to give a rough idea.  A production-ready deployment
description is captured in our deployment [readme](deploy/README.md).

### Backup and Restore

Restore:

1. With a working instance deployed.
1. Download the backup desired from the instance's S3 bucket.
1. Transfer the backup to the instance.
1. SSH to instance
1. Unpack the backup into pcmt.sql file
1. Run `make dev-import-sql`
### Logs

Most logs can be accessed through the typical docker logging mechanism:  `docker log <container name>`.

There are a few logs however that can only be accessed within the container:

- fpm
    - `/srv/pim/var/logs`
        - `dev.log` & `prod.log`: Symfony logs, including from Akeneo and extensions (e.g. PCMT)
- httpd
    - `/var/log`
        - `akeneo_access.log` & `akeneo_error.log`:  apache access and error log

### Migrations

PCMT is using standard Doctrine migrations mechanism, same as Akeneo.
PCMT migrations configuration is different than the Akeneo migrations configuration
(it has a separate directory for migration files and separate table for migrations already run) -
it is defined in `config/pcmt_migrations.yml` file.

PCMT migrations are run automatically each time the application is deployed.

#### Creating PCMT migration

Run `make dev-pcmt-migration-generate`. The new file will be added to folder
`PcmtCoreBundle/upgrades/schema`.

#### Running PCMT migration manually

If you want to run PCMT migrations manually, type `make dev-pcmt-migrate`.

### Updating Javascript's dependencies

In case of issues related to the lack of access to the Akeneo's `package.json` file, we decided to add this file to our repository. The advantage is that from now, we have possibility to control version of each library used by frontend part of the project. But on the other side, we have also a big drawback which is complex process of updating the `package.json` content.

#### How to update Akeneo PIM version?

1. Update Akeneo version in `composer.json`
1. Go to container with `make dev-fpm` and update dependencies with `COMPOSER_MEMORY_LIMIT=-1 composer update`
1. Update `AKENEO_VER` in `pim/build-images.sh`
1. In `pim/Dockerfile` comment out the `ADD --chown=docker:docker package.json /srv/pim/` line.
1. Run `make dev-clean` command, which will clean up your local environment (so be sure if you are able to do it, and that you have all your changes saved).
1. Run `make` command to build the newest version of the PCMT Docker image.
1. Run `make dev-up` and wait until your environment will be ready.
1. Run `make dev-cp-package-json` command. This command is responsible for copying the `package.json` file from running fpm Docker container to your local codebase.
1. Uncomment the `ADD --chown=docker:docker package.json /srv/pim/` line in `pim/Dockerfile`.
1. Commit your changes and push them to the remote repository.
  
