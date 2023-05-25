# ToolFactory dev server in docker
# No persistence!
# Export and save histories or tools before shutting down

FROM ubuntu:latest
MAINTAINER Ross Lazarus <ross.lazarus@gmail.com>
ARG GALAXY_USER="galaxy" \
  ORELDIR="/tmp/galaxy_tf_overlay-main" \
  USE_DB_URL="sqlite:///$OURDIR/database/universe.sqlite?isolation_level=IMMEDIATE" \
  GALAXY_UID=1450 \
  GALAXY_GID=1450 \
  GALAXY_HOME="/work/galaxytf" \
  OVERLAY_HOME="/work/galaxy_tf_overlay-main" \
  OVERLAY_ZIP="https://github.com/fubar2/galaxy_tf_overlay/archive/refs/heads/main.zip"

RUN mkdir -p /work \
  && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache \
  && echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
  && apt-get -qq update && apt-get install --no-install-recommends -y locales \
  && locale-gen en_US.UTF-8 \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && apt-get install --no-install-recommends -y python3 python3-venv python3-pip python3-wheel wget unzip nano git nodeenv \
  && apt-get autoremove -y && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache/ \
  && rm -rf /tmp/* /root/.cache/ /var/cache/* \
  && groupadd -r $GALAXY_USER -g $GALAXY_GID \
  && adduser --system --quiet --home /home/galaxy --uid $GALAXY_UID --gid $GALAXY_GID --shell /usr/bin/bash $GALAXY_USER \
  && chown -R $GALAXY_USER:$GALAXY_USER /work \
  && rm -rf /tmp/* /root/.cache/* /var/cache/*

USER galaxy
RUN wget $OVERLAY_ZIP -O /tmp/overlay.zip  && unzip /tmp/overlay.zip -d /work && cd $OVERLAY_HOME \
  && sh $OVERLAY_HOME/localtf.sh \
  && rm -rf $GALAXY_HOME/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm/ $OVERLAY_HOME
# localtf.sh clones the 23.0 release, then overlays galaxy_tf_overlay files, to add all the ToolFactory features and code
# tfsetup.sh configures those additions by generating API keys and adding them to the relevant code and installs the sample history/wf
EXPOSE 8080
WORKDIR $GALAXY_HOME
CMD ["/usr/bin/sh", "/work/galaxytf/run.sh"]
