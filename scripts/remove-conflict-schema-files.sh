#!/bin/bash
######################################################################
# Copyright (c) 2024, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

# path of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# get path to upgrades schema dir
UPGRADE_PATH="$DIR/../upgrades/schema"

#files to remove, cause migration to fail
filenames=("$UPGRADE_PATH/Version_4_0_20191031124707_update_from_clients_to_connections.php" "$UPGRADE_PATH/Version_4_0_20200116122239_remove_product_empty_raw_values.php")

for filename in ${filenames[@]}; do
    if [ -f $filename ]; then
        echo "$filename exists."
        rm $filename
        echo "$filename removed."
    else
        echo "$filename does not exist."
    fi
done