#!/bin/bash
######################################################################
# Copyright (c) 2024, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

# path of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

MYSQL_ROOT=$( sed '1!d' "$DIR/../conf/mysql-root-password.dist" )

#files to remove, cause migration to fail
docker-compose exec fpm bash scripts/remove-conflict-schema-files.sh

cd "$DIR/.."

#update table draft
docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT akeneo_pim <<< "ALTER TABLE pcmt_catalog_product_draft MODIFY productData JSON NOT NULL COMMENT '';"

#migrate
make migrate

#schema
make schema-update

#update_discriminator
docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT akeneo_pim < scripts/update_tables_with_discriminator.sql

#move_reference_data
docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT akeneo_pim < scripts/move_reference_data.sql

#add GDSN_Unit_Of_Measure
docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT akeneo_pim < scripts/akeneo_measurement_GDSN_Unit_Of_Measure.sql

#reset-indexes
make reset-indexes

#product-model-index
make product-model-index

#product-index
make product-index

#cache-clear
make cache-clear



