#!/bin/bash
######################################################################
# Copyright (c) 2024, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

FROM alpine:3.20 AS azure-restore

RUN apk add bash

ADD cmd-to-run.sh /cmd-to-run.sh
RUN chmod u+x /cmd-to-run.sh

RUN apk -v --update add --no-cache \
    py3-pip \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev \
    cargo \
    mysql-client \
    make \
    && \
    pip3 install  --upgrade pip --break-system-packages && \
    pip3 install  azure-cli --break-system-packages && \
    rm /var/cache/apk/*

ENTRYPOINT ["/cmd-to-run.sh"]