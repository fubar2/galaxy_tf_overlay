# ToolFactory dev server in docker
# No persistence!
# Export and save histories or tools before shutting down

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
  GAL_USER="galaxy" \
  USE_DB_URL="sqlite:///$OURDIR/database/universe.sqlite?isolation_level=IMMEDIATE" \
  GALAXY_VIRTUAL_ENV="/work/galaxytf/.venv"
  #USE_DB_URL="postgresql:///galaxydev?host=/var/run/postgresql"
  #database_connection: "postgresql:///galaxydev?host=/var/run/postgresql"

RUN mkdir -p /work \
  && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache \
  && echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
  && apt-get -qq update \
  && apt-get install --no-install-recommends -y locales \
  && locale-gen en_US.UTF-8 \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && apt-get install --no-install-recommends -y python3 python3-venv python3-pip python3-wheel wget unzip nano git nodeenv sudo \
  && groupadd -r $GALAXY_USER -g $GALAXY_GID \
  && adduser --system --quiet --home /home/galaxy --uid $GALAXY_UID --gid $GALAXY_GID --shell /usr/bin/bash $GALAXY_USER \
  && cd /work \
  && wget $GALZIP \
  && unzip $REL.zip \
  && mv $RELDIR $GALAXY_ROOT \
  && chown -R $GALAXY_USER:$GALAXY_USER /work \
  &&  python3 -m venv $GALAXY_VIRTUAL_ENV \
  && cd $GALAXY_ROOT \
  && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_ROOT \
  && echo ". $GALAXY_VIRTUAL_ENV/bin/activate && export GALAXY_ROOT=$GALAXY_ROOT && export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV \
     && export VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV \
     && cd $GALAXY_ROOT && sh $GALAXY_ROOT/scripts/common_startup.sh --no-create-venv" > /tmp/runme.sh \
  && su $GALAXY_USER /tmp/runme.sh \
  && chown -R $GALAXY_USER:$GALAXY_USER /work \
  && apt-get autoremove -y && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache/ \
  && rm -rf /root/.cache/ /var/cache/* \
  && rm -rf $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm/
# is this a good idea - must test: RUN find /galaxytf -name '*.pyc' -delete | true \
USER galaxy
# client is built so now can install the overlay
# change this section to force quay.io to not use the cached copy of the git repository
RUN wget $OVERLAY_ZIP -O /tmp/overlay.zip \
  && unzip /tmp/overlay.zip -d /work \
  && cd $OVERLAY_HOME  && sh $OVERLAY_HOME/localtf_docker.sh  $GALAXY_ROOT \
  && rm -rf $OVERLAY_HOME /home/galaxy/.cache
  # overlays galaxy_tf_overlay files, to add all the ToolFactory features and code
  # Calls tfsetup.sh to configure those overlays by generating API keys and adding them to the relevant code, then installs the sample history/wf
EXPOSE 8080
WORKDIR $GALAXY_ROOT
CMD ["/usr/bin/sh", "/work/galaxytf/run.sh"]
