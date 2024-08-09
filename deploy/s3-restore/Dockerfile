#!/bin/bash
######################################################################
# Copyright (c) 2020, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

FROM alpine:3.11 AS s3-restore

RUN apk add bash

ADD cmd-to-run.sh /cmd-to-run.sh
RUN chmod u+x /cmd-to-run.sh

RUN apk -v --update add \
        libmagic \
        python \
        py-pip \
        mysql-client \
        && \
    pip install --upgrade s3cmd python-magic && \
    apk -v --purge del py-pip && \
    rm /var/cache/apk/*

ENTRYPOINT ["/cmd-to-run.sh"]