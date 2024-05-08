#!/bin/bash
######################################################################
# Copyright (c) 2024, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

# path of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

MYSQL_ROOT=$( sed '1!d' "$DIR/../conf/mysql-root-password.dist" )


cd "$DIR/.."
#cache-clear
make cache-clear

# Update productModel inventory_item_uuid with newly generated UUIDs
while read -r productId; do
  NEW_UUID=$(uuidgen)
  docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT akeneo_pim <<< "UPDATE pim_catalog_product_model SET inventory_item_uuid = '$NEW_UUID' WHERE id = $productId;"
done < <(mysql -h localhost -u root -p$MYSQL_ROOT akeneo_pim -N -e "SELECT id FROM pim_catalog_product_model;")  


# Update product inventory_item_uuid with newly generated UUIDs
while read -r productId; do
  NEW_UUID=$(uuidgen)
  docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT akeneo_pim <<< "UPDATE pim_catalog_product SET inventory_item_uuid = '$NEW_UUID' WHERE id = $productId;"
done < <(mysql -h localhost -u root -p$MYSQL_ROOT akeneo_pim -N -e "SELECT id FROM pim_catalog_product;")  


