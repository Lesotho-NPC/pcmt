######################################################################
# Copyright (c) 2024, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

FROM pcmt/cron:latest

RUN apk add --no-cache py3-pip gcc musl-dev python3-dev libffi-dev openssl-dev cargo make && \
    pip3 install  --upgrade pip --break-system-packages && \
    pip3 install  azure-cli --break-system-packages
