######################################################################
# Copyright (c) 2019, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

FROM librespace/ansible:9.6.0

ADD docker-entrypoint.sh /docker-entrypoint.sh
COPY . /tmp
WORKDIR /tmp
RUN apt-get update && \
    apt-get install -y openssh-client && \
    apt-get clean && \
    apt-get autoremove && \
    pip install -r requirements/ansible.pip && \
    ansible-galaxy collection install -r requirements/galaxy.yml && \
    ansible-galaxy role install -p vendor/roles -r requirements/galaxy.yml && \
    chmod 770 /tmp

ENTRYPOINT ["/docker-entrypoint.sh"]