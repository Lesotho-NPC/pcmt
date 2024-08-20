#!/bin/bash
######################################################################
# Copyright (c) 2024, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################
: "${CRED_PATH:=/run/secrets/azure-creds}"
if [ ! -r "$CRED_PATH" ]; then
    echo "$CRED_PATH not readable"
    exit 1
fi

set -o allexport
source $CRED_PATH
set +o allexport

: "${AZURE_STORAGE_ACCOUNT:?AZURE_STORAGE_ACCOUNT not set}"
: "${AZURE_STORAGE_KEY:?AZURE_STORAGE_KEY not set}"

: "${AZURE_STORAGE_CONTAINER_NAME:?AZURE_STORAGE_CONTAINER_NAME not set}"
: "${LOCAL_DIR_TO_SYNC_OUT:=/backup}"

if [ ! -r "$LOCAL_DIR_TO_SYNC_OUT" ]; then
    echo "Directory not readable to sync: $LOCAL_DIR_TO_SYNC_OUT"
    exit 1
fi

echo "Uploading to Azure..."
az storage blob upload-batch --account-name "$AZURE_STORAGE_ACCOUNT" --destination "$AZURE_STORAGE_CONTAINER_NAME" --source "$LOCAL_DIR_TO_SYNC_OUT"


if [ $? == 0 ]; then
    echo "Removing local copies..."
    find "$LOCAL_DIR_TO_SYNC_OUT" -type f -print -delete
fi