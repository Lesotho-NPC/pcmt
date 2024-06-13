#!/bin/bash
######################################################################
# Copyright (c) 2019, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

TF_ENV=$1
TF_CMD="${@:2}"

# check if atleast one credential file exists
[ ! -r "$AWS_SHARED_CREDENTIALS_FILE" ]
AWS_CREDS_EXIST=$?
[ ! -r "$AZURE_CREDENTIALS_FILE" ]
AZURE_CREDS_EXIST=$?
if (( AWS_CREDS_EXIST == 0 )) && (( AZURE_CREDS_EXIST == 0 )); then
    echo "ERROR: No credential files present"
    ls -alR /tmp/instance
    exit 1
fi

# export azure credentials to shell if they exist
if (( AZURE_CREDS_EXIST == 1 )); then
    set -o allexport
    source "$AZURE_CREDENTIALS_FILE"
    set +o allexport
fi

if [ ! -r "/var/run/docker.sock" ]; then
    echo Docker socket not mounted
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Environment isn't known directory: $1"
    exit 1
fi

SSH_KEY="/tmp/instance/id_rsa"
if [ ! -r "$SSH_KEY" ] || [ ! -f "$SSH_KEY" ]; then
    echo "SSH Key $SSH_KEY not accessible"
    exit 1
fi

mkdir -p /root/.ssh
cp "$SSH_KEY" /root/.ssh
chmod 700 /root/.ssh
chmod 400 /root/.ssh/*

echo Starting ssh-agent and adding default key
eval "$(ssh-agent -s)"
ssh-add

echo "On environment $TF_ENV, running terraform $TF_CMD"
cd "$TF_ENV" || exit 1

terraform init
terraform "${@:2}"
