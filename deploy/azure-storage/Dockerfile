#!/bin/bash
######################################################################
# Copyright (c) 2024, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

FROM pcmt/cron:latest

# Install necessary packages including Azure CLI
RUN apk -v --update add \
        bash \
        libmagic \
        python3 \
        py3-pip \
        curl \
        && \
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    apk -v --purge del py3-pip && \
    rm /var/cache/apk/*