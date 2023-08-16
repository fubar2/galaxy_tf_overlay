# Dev server in docker as first layer, then the ToolFactory overlay configuration is installed and set up
# with default admin, history, workflow and ToolFactory dependencies installed
# This has none of the features of Bjoern's docker-galaxy-stable - uses sqlite for example, but
# has the latest release 23.0 in the latest ubuntu image FWIW.
# No persistence so export and save histories or tools before shutting down


FROM ubuntu:22.04
MAINTAINER Ross Lazarus <ross.lazarus@gmail.com>
USER root
# save downloading and allow hacking locally to be effective during development ;)
COPY . /work/galaxy_tf_overlay-main/

ARG ORELDIR=/tmp/galaxy_tf_overlay-main \
  OVERLAY_HOME=/work/galaxy_tf_overlay-main \
  OVERLAY_ZIP=https://github.com/fubar2/galaxy_tf_overlay/archive/refs/heads/main.zip \
  REL=release_23.0 \
  RELDIR=galaxy-release_23.0 \
  GALZIP=https://github.com/galaxyproject/galaxy/archive/refs/heads/release_23.0.zip \
  GALAXY_USER=galaxy \
  GALAXY_UID=1450 \
  GALAXY_GID=1450 \
  GALAXY_ROOT=/work/galaxytf \
  GALAXY_HOME=/home/galaxy

ENV GALAXY_USER=galaxy \
  GALAXY_ROOT=/work/galaxytf  \
  GALAXY_VIRTUAL_ENV=/work/galaxytf/.venv \
  GALAXY_INSTALL_PREBUILT_CLIENT=1 \
  USE_DB_URL=sqlite:////work/galaxytf/database/universe.sqlite?isolation_level=IMMEDIATE \
  GALAXY_CONDA_PREFIX=/work/galaxytf/database/dependencies/_conda

RUN mkdir -p /work \
  && apt-get -q update \
  && apt-get install --no-install-recommends -y locales apt-utils curl \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && apt-get install -q --no-install-recommends -y python3 python3-venv python3-pip python3-wheel wget unzip git nano nodeenv sudo \
  && groupadd -r galaxy -g 1450 \
  && adduser --system  --home /home/galaxy --uid 1450 --gid 1450 --shell /usr/bin/bash galaxy \
  && cd /work \
  && wget -q $GALZIP \
  && unzip -qq $REL.zip \
  && rm -rf $REL.zip \
  && mv $RELDIR $GALAXY_ROOT \
  && python3 -m venv $GALAXY_VIRTUAL_ENV \
  && cd $GALAXY_ROOT \
  && chown -R galaxy:galaxy /work \
  && echo ". $GALAXY_VIRTUAL_ENV/bin/activate && export GALAXY_ROOT=$GALAXY_ROOT && export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV \
     && export VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV \
     && export GALAXY_INSTALL_PREBUILT_CLIENT=1 \
     && cd $GALAXY_ROOT && sh $GALAXY_ROOT/scripts/common_startup.sh --no-create-venv \
     && . $GALAXY_ROOT/scripts/common_startup_functions.sh \
     && cp $OVERLAY_HOME/scripts/localtf_docker.sh $GALAXY_ROOT/scripts/ \
    && sh $OVERLAY_HOME/scripts/localtf_docker.sh  $GALAXY_ROOT $OVERLAY_HOME" > /tmp/runme.sh \
  && cat /tmp/runme.sh \
  && su -l galaxy /tmp/runme.sh \
  && chown -R galaxy:galaxy /work  \
  && apt-get autoremove -y && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache/ /var/cache/*  \
        $GALAXY_VIRTUAL_ENV/src/ \
        /home/$GALAXY_USER/.npm/ $GALAXY_ROOT/config/plugins \
  && find / -name '*.log' -delete  \
  && truncate -s 0 /var/log/*log || true \
  && rm -rf .ci .circleci .coveragerc .gitignore .travis.yml CITATION CODE_OF_CONDUCT.md CONTRIBUTING.md CONTRIBUTORS.md \
              LICENSE.txt Makefile README.rst SECURITY_POLICY.md pytest.ini tox.ini \
              contrib doc lib/galaxy_test test test-data

USER galaxy

EXPOSE 8080
WORKDIR $GALAXY_ROOT
CMD ["/usr/bin/sh", "/work/galaxytf/run.sh"]
