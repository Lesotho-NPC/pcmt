#!/bin/bash
######################################################################
# Copyright (c) 2024, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

: "${CRED_PATH:=/run/secrets/azure-creds}"
if [[ ! -r "$CRED_PATH" ]]; then
    echo "$CRED_PATH not readable"
    exit 1
fi

: "${MYSQL_CRED_PATH:=/run/secrets/mysql-creds}"
if [[ ! -r "$MYSQL_CRED_PATH" ]]; then
    echo "$MYSQL_CRED_PATH not readable"
    exit 1
fi

set -o allexport
source $CRED_PATH
source $MYSQL_CRED_PATH
set +o allexport

: "${AZURE_STORAGE_ACCOUNT:?AZURE_STORAGE_ACCOUNT not set}"
: "${AZURE_STORAGE_CONTAINER_NAME:?AZURE_STORAGE_CONTAINER_NAME not set}"
: "${LOCAL_DIR_TO_SYNC_IN:=/backup/}"
: "${DB_HOST:?DB_HOST not found}"
: "${DB_PORT:?DB_PORT not found}"
: "${DB_NAME:?DB_NAME not found}"
: "${DB_USER:?DB_USER not found}"
: "${DB_PASS:?DB_PASS not found}"

if [[ ! -d $LOCAL_DIR_TO_SYNC_IN ]]; then
    mkdir $LOCAL_DIR_TO_SYNC_IN
fi

if [[ ! -r "$LOCAL_DIR_TO_SYNC_IN" ]]; then
    echo "Directory not readable to sync: $LOCAL_DIR_TO_SYNC_IN"
    exit 1
fi

# List blobs with last-modified timestamp and filter by extension
blob_names=$(az storage blob list --account-name $AZURE_STORAGE_ACCOUNT --container-name $AZURE_STORAGE_CONTAINER_NAME --output json --query "sort_by([].{Name:name, LastModified:properties.lastModified}, &LastModified)[-2:]")

# Download the latest blob
echo "$blob_names" | jq -r '.[] | .Name' | while read blob_name; do
  echo "Downloading blob: $blob_name"
  az storage blob download \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --container-name $AZURE_STORAGE_CONTAINER_NAME \
    --name "$blob_name" \
    --file "$LOCAL_DIR_TO_SYNC_IN$blob_name"
done


#drop database
echo "Dropping database..."
mysql \
  -h "$DB_HOST" \
  --port="$DB_PORT" \
  -u "$DB_USER" \
  -p"$DB_PASS" \
  -e "DROP DATABASE $DB_NAME;"
retVal=$?

if [[ $retVal -eq 0 ]]; then
  echo "Database $DB_NAME dropped!"
fi

#create database
echo "Create database..."
mysql \
  -h "$DB_HOST" \
  --port="$DB_PORT" \
  -u "$DB_USER" \
  -p"$DB_PASS" \
  -e "CREATE DATABASE $DB_NAME;"
retVal=$?

if [[ $retVal -eq 0 ]]; then
  echo "Database $DB_NAME created!"
fi

cd "$LOCAL_DIR_TO_SYNC_IN"

# Check for .gzip files and unarchive them
for file in $(ls -1); do
    if [[ -f "$file" ]]; then
      if [[ $file == *.gz ]]; then
        echo "Unarchiving: $file"
        gunzip < "$file" | mysql \
          -h "$DB_HOST" \
          --port="$DB_PORT" \
          -u "$DB_USER" \
          -p"$DB_PASS" \
          "$DB_NAME"
        retVal=$?

        if [[ $retVal -eq 0 ]]; then
          echo "Backup restored from:  $file"
        else
          echo "Database backup restoration fail!"
        fi
      elif [[ $file == *.tgz ]]; then
        echo "Unarchiving assets: $file"
        tar -xf "$file" --strip-components=2 -C /file_storage/

        if [[ $? -eq 0 ]]; then
          echo "Assets restored!"
        else
          echo "Assets restoration failed!"
        fi
      fi
    fi
done

if [[ $? == 0 ]]; then
    echo "Removing local copies..."
    find "$LOCAL_DIR_TO_SYNC_IN" -type f -print -delete
fi