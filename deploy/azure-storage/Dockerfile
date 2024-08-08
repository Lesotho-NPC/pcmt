######################################################################
# Copyright (c) 2024, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

FROM pcmt/cron:latest

RUN apk add --no-cache py3-pip gcc musl-dev python3-dev libffi-dev openssl-dev cargo make && \
    pip3 install --break-system-packages --upgrade pip && \
    pip3 install --break-system-packages azure-cli
