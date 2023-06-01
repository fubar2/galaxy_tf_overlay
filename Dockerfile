# Dev server in docker as first layer, then the ToolFactory overlay configuration is installed and set up
# with default admin, history, workflow and ToolFactory dependencies installed
# This has none of the features of Bjoern's docker-galaxy-stable - uses sqlite for example, but
# has the latest release 23.0 in the latest ubuntu image FWIW.
# No persistence so export and save histories or tools before shutting down
#  and NO visualisations - the config/plugins/visualizations take 3GB of disk

FROM ubuntu:latest
MAINTAINER Ross Lazarus <ross.lazarus@gmail.com>
ARG GALAXY_USER="galaxy" \
  USE_DB_URL="sqlite:////work/galaxytf/database/universe.sqlite?isolation_level=IMMEDIATE" \
  ORELDIR="/tmp/galaxy_tf_overlay-main" \
  GALAXY_UID=1450 \
  GALAXY_GID=1450 \
  GALAXY_ROOT="/work/galaxytf" \
  OVERLAY_HOME="/work/galaxy_tf_overlay-main" \
  OVERLAY_ZIP="https://github.com/fubar2/galaxy_tf_overlay/archive/refs/heads/main.zip" \
  REL="release_23.0" \
  RELDIR="galaxy-release_23.0" \
  GALZIP="https://github.com/galaxyproject/galaxy/archive/refs/heads/release_23.0.zip" \
  USE_DB_URL="sqlite:////work/galaxytf/database/universe.sqlite?isolation_level=IMMEDIATE" \
  GALAXY_VIRTUAL_ENV="/work/galaxytf/.venv"

RUN mkdir -p /work \
  && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache \
  && echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
  && apt-get -qq update \
  && apt-get install --no-install-recommends -y locales apt-utils \
  && locale-gen en_US.UTF-8 \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && apt-get install --no-install-recommends -y python3 python3-venv python3-pip python3-wheel wget unzip nano git nodeenv sudo \
  && groupadd -r $GALAXY_USER -g $GALAXY_GID \
  && adduser --system --quiet --home /home/galaxy --uid $GALAXY_UID --gid $GALAXY_GID --shell /usr/bin/bash $GALAXY_USER \
  && cd /work \
  && wget $GALZIP \
  && unzip $REL.zip \
  && mv $RELDIR $GALAXY_ROOT \
  # save 3GB of disk space but plugin visualisations will not work
  && rm -rf $GALAXY_ROOT/config/plugins/visualizations/* \
  && chown -R $GALAXY_USER:$GALAXY_USER /work \
  && python3 -m venv $GALAXY_VIRTUAL_ENV \
  && cd $GALAXY_ROOT \
  && chown -R $GALAXY_USER:$GALAXY_USER /work \
  && echo ". $GALAXY_VIRTUAL_ENV/bin/activate && export GALAXY_ROOT=$GALAXY_ROOT && export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV \
     && export VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV \
     && cd $GALAXY_ROOT && sh $GALAXY_ROOT/scripts/common_startup.sh --no-create-venv \
     && . $GALAXY_ROOT/scripts/common_startup_functions.sh \
     && setup_python" > /tmp/runme.sh \
  && su $GALAXY_USER /tmp/runme.sh \
  && apt-get autoremove -y && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache/ \
  && rm -rf /root/.cache/ /var/cache/* \
  && rm -rf $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/$GALAXY_USER/.npm/ $GALAXY_ROOT/config/plugins
USER galaxy
# Galaxy client is built. Now overlay configuration and code, and setup ToolFactory requirements like logins and API keys.
# edit this section to force quay.io to not use the cached copy of the git repository if it gets updated.
RUN wget $OVERLAY_ZIP -O /tmp/overlay.zip \
  && unzip /tmp/overlay.zip -d /work \
  && cd $OVERLAY_HOME  && sh $OVERLAY_HOME/localtf_docker.sh  $GALAXY_ROOT $OVERLAY_HOME \
  && rm -rf /home/galaxy/.cache \
  && ls -l # force rebuild of this layer
EXPOSE 8080
WORKDIR $GALAXY_ROOT
CMD ["/usr/bin/sh", "/work/galaxytf/run.sh"]
