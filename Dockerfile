# Dev server in docker as first layer, then the ToolFactory overlay configuration is installed and set up
# with default admin, history, workflow and ToolFactory dependencies installed
# This has none of the features of Bjoern's docker-galaxy-stable - uses sqlite for example, but
# has the latest release 23.0 in the latest ubuntu image FWIW.
# No persistence so export and save histories or tools before shutting down
#  and NO visualisations - the config/plugins/visualizations take 3GB of disk

FROM ubuntu:latest
MAINTAINER Ross Lazarus <ross.lazarus@gmail.com>

ENV GALAXY_USER="galaxy" \
  #FOO="do not cacheme" \
  VER="23.0" \
  GALAXY_UID=1450 \
  GALAXY_GID=1450 \
  GALAXY_ROOT="/work/galaxytf"  \
  GALAXY_VIRTUAL_ENV="/work/galaxytf/.venv" \
  GALAXY_INSTALL_PREBUILT_CLIENT=1 \
  GALAXY_CONDA_PREFIX="/work/galaxytf/database/dependencies/_conda"

ARG USE_DB_URL="sqlite:////work/galaxytf/database/universe.sqlite?isolation_level=IMMEDIATE" \
  ORELDIR="/tmp/galaxy_tf_overlay-main" \
  OVERLAY_HOME="/work/galaxy_tf_overlay-main" \
  OVERLAY_ZIP="https://github.com/fubar2/galaxy_tf_overlay/archive/refs/heads/main.zip" \
  VER="23.0" \
  REL="release_$VER" \
  RELDIR="galaxy-release_$VER" \
  GALZIP="https://github.com/galaxyproject/galaxy/archive/refs/heads/release_$VER.zip" \
  USE_DB_URL="sqlite:////work/galaxytf/database/universe.sqlite?isolation_level=IMMEDIATE" \
  GALAXY_HOME="/home/galaxy"

RUN mkdir -p /work \
  #&& echo "do not cache me" \
  && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache \
  && echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
  && apt-get -qq update \
  && apt-get install --no-install-recommends -y locales apt-utils curl \
  && locale-gen en_US.UTF-8 \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && apt-get install -qq --no-install-recommends -y python3 python3-venv python3-pip python3-wheel wget unzip git nano nodeenv sudo \
  && groupadd -r $GALAXY_USER -g $GALAXY_GID \
  && adduser --system --quiet --home /home/galaxy --uid $GALAXY_UID --gid $GALAXY_GID --shell /usr/bin/bash $GALAXY_USER \
  && cd /work \
  && wget -q $GALZIP \
  && unzip $REL.zip \
  && mv $RELDIR $GALAXY_ROOT \
  && python3 -m venv $GALAXY_VIRTUAL_ENV \
  && cd $GALAXY_ROOT \
  && chown -R galaxy:galaxy /work \
  && echo ". $GALAXY_VIRTUAL_ENV/bin/activate && export GALAXY_ROOT=$GALAXY_ROOT && export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV \
     && export VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV \
     && cd $GALAXY_ROOT && sh $GALAXY_ROOT/scripts/common_startup.sh --no-create-venv \
     && . $GALAXY_ROOT/scripts/common_startup_functions.sh" > /tmp/runme.sh \
  && cat /tmp/runme.sh \
  && su $GALAXY_USER /tmp/runme.sh \
  && wget -q $OVERLAY_ZIP -O /tmp/overlay.zip \
  && unzip -qq /tmp/overlay.zip -d /work \
  && chown -R galaxy:galaxy /work \
  && echo ". $GALAXY_VIRTUAL_ENV/bin/activate && cd $OVERLAY_HOME && sh $OVERLAY_HOME/localtf_docker.sh  $GALAXY_ROOT $OVERLAY_HOME" > /tmp/runme2.sh \
  && su $GALAXY_USER /tmp/runme2.sh \
  && rm -rf /home/galaxy/.cache \
  && apt-get autoremove -y && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache/ /var/cache/*  \
        /home/$GALAXY_USER/.npm/ $GALAXY_ROOT/config/plugins \
  && find / -name '*.log' -delete && find / -name '.cache' -delete \
  && rm -rf .ci .circleci .coveragerc .gitignore .travis.yml CITATION CODE_OF_CONDUCT.md CONTRIBUTING.md CONTRIBUTORS.md \
              LICENSE.txt Makefile README.rst SECURITY_POLICY.md pytest.ini tox.ini \
              contrib doc
USER galaxy

EXPOSE 8080
WORKDIR $GALAXY_ROOT
CMD ["/usr/bin/sh", "/work/galaxytf/run.sh"]
