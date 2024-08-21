#!/bin/bash
######################################################################
# Copyright (c) 2019, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

: "${AWS_SHARED_CREDENTIALS_FILE:=$HOME/.aws/credentials}"
: "${AZURE_CREDENTIALS_FILE:=$HOME/.azure/azure-creds}"
: "${SSH_PRIV_KEY_PATH:=$HOME/.ssh/id_rsa}"
HELPER_CONTAINER="pcmt-tf-helper"
SECRETS_VOL="pcmt-secrets-tf"
INSTANCE_CREDS_VOL="pcmt-instance-creds-tf"

function cleanup {
    prevExit="$?"
    echo "Cleaning up container and volumes..."
    docker rm "$HELPER_CONTAINER"
    docker volume rm "$INSTANCE_CREDS_VOL"
    docker volume rm "$SECRETS_VOL"
    exit $prevExit
}
trap cleanup EXIT

# copies file whose path is in param 1, into the helper container at path
#  given in param 2
cpFileFromEnvIntoHelper() {
    filePath=$1
    volPath=$2
    if [[ -f "$filePath" && -r "$filePath" ]]; then
        docker cp "$filePath" "$HELPER_CONTAINER":"$volPath"
        echo "Secret set: $volPath from $filePath"
    else
        echo "Secret not set: $volPath"
    fi
}

# check SSH key is available
if [ ! -r "$SSH_PRIV_KEY_PATH" ] || [ ! -f "$SSH_PRIV_KEY_PATH" ]; then
    echo "SSH Key $SSH_PRIV_KEY_PATH not accessible"
    exit 1
fi

# setup ssh and secrets volumes
echo ...Creating helper container and volumes...
docker volume create "$INSTANCE_CREDS_VOL"
docker volume create "$SECRETS_VOL"
docker run --name "$HELPER_CONTAINER" \
    -v "$INSTANCE_CREDS_VOL":/tmp/instance \
    -v "$SECRETS_VOL":/conf \
    busybox

echo ...Copying files from env to helper...

# copy creds into instance creds vol
cpFileFromEnvIntoHelper "$SSH_PRIV_KEY_PATH" "/tmp/instance/id_rsa"
cpFileFromEnvIntoHelper "$AWS_SHARED_CREDENTIALS_FILE" "/tmp/instance/aws-credentials"
cpFileFromEnvIntoHelper "$AZURE_CREDENTIALS_FILE" "/tmp/instance/azure-creds"

# copy deploy secrets into secrets volume
cpFileFromEnvIntoHelper "$AKENEO_ENV" "/conf/akeneo.env"
cpFileFromEnvIntoHelper "$PCMT_ENV" "/conf/pcmt.env"
cpFileFromEnvIntoHelper "$PCMT_MYSQL_CREDS_CONF" "/conf/mysql-creds.env"
cpFileFromEnvIntoHelper "$PCMT_S3_CREDS_CONF" "/conf/aws-s3-creds.env"
cpFileFromEnvIntoHelper "$AZURE_CREDENTIALS_FILE" "/conf/azure-creds.env"
cpFileFromEnvIntoHelper "$PCMT_FTP_GET_CREDS_CONF" "/conf/ftp-get-creds.env"
cpFileFromEnvIntoHelper "$PCMT_FTP_PUT_CREDS_CONF" "/conf/ftp-put-creds.env"
cpFileFromEnvIntoHelper "$PCMT_SFTP_PRIVKEY_FILENAME" "/conf/sftp-privkey"
cpFileFromEnvIntoHelper "$PCMT_SCALYR_CREDS_CONF" "/conf/scalyr-creds.json"
cpFileFromEnvIntoHelper "$PCMT_MYSQL_ROOT_PASSWORD_CONF" \
    "/conf/mysql-root-password.dist"
cpFileFromEnvIntoHelper "$PCMT_MYSQL_USERNAME_CONF" \
    "/conf/mysql-username.dist"
cpFileFromEnvIntoHelper "$PCMT_MYSQL_PASSWORD_CONF" \
    "/conf/mysql-password.dist"

docker run --rm \
    -e AWS_SHARED_CREDENTIALS_FILE="/tmp/instance/aws-credentials" \
    -e AZURE_CREDENTIALS_FILE="/tmp/instance/azure-creds" \
    -e PCMT_PROFILE \
    -e PCMT_VER \
    -e PCMT_ASSET_URL \
    -e DOCKER_PROFILES \
    -e AZURE_STORAGE_KEY \
    -e AZURE_STORAGE_ACCOUNT \
    -e PCMT_SECRETS_VOLUME="$SECRETS_VOL" \
    -e PCMT_INSTANCE_CREDS_VOLUME="$INSTANCE_CREDS_VOL" \
    -v "$SECRETS_VOL":/conf \
    -v "$INSTANCE_CREDS_VOL":/tmp/instance \
    -v "/var/run/docker.sock:/var/run/docker.sock" \
    -v "$DIR/env:/app/env" \
    pcmt/terraform:v6 "${@}"