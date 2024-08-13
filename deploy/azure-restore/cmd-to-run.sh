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

mkdir $LOCAL_DIR_TO_SYNC_IN

if [[ ! -r "$LOCAL_DIR_TO_SYNC_IN" ]]; then
    echo "Directory not readable to sync: $LOCAL_DIR_TO_SYNC_IN"
    exit 1
fi

extensions=("tgz" "gz")

# List blobs with last-modified timestamp and filter by extension
blob_list=$(az storage blob list --account-name $AZURE_STORAGE_ACCOUNT --container-name $AZURE_STORAGE_CONTAINER_NAME --output table --query "[?endswith(Name, '${extensions[*]}')].{name:Name,lastModified:LastModified}" --delimiter '|')

# Create an array to store the latest two blobs
latest_blobs=()

# Parse output and extract blob name and last-modified timestamp
while IFS='|' read -r blob_name last_modified; do
  # Check if array is full
  if [[ ${#latest_blobs[@]} -eq 2 ]]; then
    # Replace the oldest blob if the new one is newer
    oldest_index=0
    oldest_timestamp=${latest_blobs[$oldest_index][1]}
    for ((i=1; i<${#latest_blobs[@]}; i++)); do
      if [[ ${latest_blobs[$i][1]} < $oldest_timestamp ]]; then
        oldest_index=$i
        oldest_timestamp=${latest_blobs[$i][1]}
      fi
    done
    if [[ "$last_modified" > "$oldest_timestamp" ]]; then
      latest_blobs[$oldest_index]=("$blob_name" "$last_modified")
    fi
  else
    latest_blobs+=("$blob_name" "$last_modified")
  fi
done <<< "$blob_list"

# Download the latest blob
for blob in "${latest_blobs[@]}"; do
  echo "${blob[0]} - ${blob[1]}"
  az storage blob download --account-name $AZURE_STORAGE_ACCOUNT --container-name $AZURE_STORAGE_CONTAINER_NAME --name "${blob[0]}" --file "$LOCAL_DIR_TO_SYNC_IN/${blob[0]}"
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
done

if [[ $? == 0 ]]; then
    echo "Removing local copies..."
    find "$LOCAL_DIR_TO_SYNC_IN" -type f -print -delete
fi