######################################################################
# Copyright (c) 2020, VillageReach
# Licensed under the Non-Profit Open Software License version 3.0.
# SPDX-License-Identifier: NPOSL-3.0
######################################################################

FROM scalyr/scalyr-agent-docker-json:2.0.57

ADD run.sh /run.sh
ADD agent.d /etc/scalyr-agent-2/agent.d
RUN chmod u+x /run.sh

CMD ["/run.sh"]