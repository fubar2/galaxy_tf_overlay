# build ToolFactory image
# This Dockerfile builds a development Galaxy server with a Galaxy tool to generate and test new Galaxy tools
# There is no persistence for your work! It is only for temporary use.
# To build the docker image, go to the top level directory of your training git repository and run:
#    docker build -t galaxytf -f topics/tool-generators/docker/Dockerfile .
# Take a break. Takes 20 minutes or more because it has to build a working server from the git code.
# To run the completed image:
#    docker run -p "8080:8080"  -t tool-generators
# ToolFactory development server will be available on localhost:9090
# Toolshed archives you generate can be downloaded and then unpacked under the mytools directory.
# They will be loaded by planemo into the Galaxy it runs and be available in the tool menu the next time you restart the container and planemo
# This allows you to load newly generated tools for testing and refinement.
# WARNING:
# Export your history before you shut this container down if you want to keep it. It will disappear forever otherwise!
# The exported history .tgz file can be imported next time you start up. You may need to regenerate tools by rerunning the job to reuse them.
#
# The ToolFactory always starts with the same sample history and workflow built in once you login as toolfactory@galaxy.org
# using the password 'ChangeMe!'. This won't be saved if you change it :( so please do not ever expose this development server on the open internet.
# Without the usual protection from a proper


FROM phusion/baseimage:jammy-1.0.1
MAINTAINER ross dot lazarus at gmail period com
ENV DEBIAN_FRONTEND=noninteractive \
GALAXY_ROOT=/galaxytf \
BUILD_DIR=/tf_build  \
GALAXY_USER=galaxy \
GALAXY_VIRTUAL_ENV=/galaxytf/.venv \
REL=release_23.0 \
GALZIP="https://github.com/galaxyproject/galaxy/archive/refs/heads/release_23.0.zip" \
GALAXY_CONFIG_BRAND="ToolFactory Docker" \
GALAXY_CONFIG_TOOL_CONFIG_FILE="/etc/galaxy/tool_conf.xml,/galaxy-central/local_tools/local_tool_conf.xml" \
GALAXY_CONFIG_ADMIN_USERS="admin@galaxy.org,toolfactory@galaxy.org"

RUN apt-get update && apt-get -y upgrade \
    && apt-get install -y -qq --no-install-recommends locales tzdata openssl netbase apt-utils apt-transport-https unzip supervisor \
     software-properties-common ca-certificates curl python3-dev gcc python3-pip build-essential python3-venv \
     python3-wheel nano wget git python3-setuptools gnupg mercurial lsb-release sudo \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && dpkg-reconfigure -f noninteractive tzdata \
    && groupadd -f galaxy \
    && groupadd -f postgres \
    && useradd -r -m -g galaxy galaxy \
    && useradd -r -m -g postgres postgres \
    && groupadd -f docker \
    && usermod -aG docker galaxy \
    && mkdir -p $GALAXY_ROOT $BUILD_DIR \
    && cd $BUILD_DIR \
    && git clone --depth 1 https://github.com/fubar2/galaxy_tf_overlay.git \
   && wget $GALZIP \
   && unzip $REL.zip \
   && mv $BUILD_DIR/galaxy-$REL/* $GALAXY_ROOT/  \
   && cd $GALAXY_ROOT \
   && cp -rv $BUILD_DIR/galaxy_tf_overlay/* $GALAXY_ROOT/ \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get -y update  \
   && apt-get install -y docker-ce-cli docker-ce containerd.io docker-compose-plugin \
    && printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d \
   && apt-get install -y postgresql-14 \
    && python3 -m venv $GALAXY_VIRTUAL_ENV \
    && chown -R galaxy:galaxy $GALAXY_ROOT  $BUILD_DIR $GALAXY_VIRTUAL_ENV  /home/galaxy \
    && service postgresql start \
   && sudo -u postgres /usr/bin/psql -c "create role $GALAXY_USER with login createdb;" \
   && sudo -u postgres /usr/bin/psql -c "DROP DATABASE IF EXISTS galaxydev;" \
   && sudo -u postgres /usr/bin/psql -c "create database galaxydev;" \
   && sudo -u postgres /usr/bin/psql -c "grant all privileges on database galaxydev to $GALAXY_USER;"

USER $GALAXY_USER
RUN cd $GALAXY_ROOT \
  && . $GALAXY_VIRTUAL_ENV/bin/activate \
  && sh scripts/common_startup.sh --no-create-venv \
  && pip3 install bioblend ephemeris  planemo \
  && python3 scripts/tfsetup.py --galaxy_root $GALAXY_ROOT --force

USER root
RUN service postgresql stop \
    && find $GALAXY_ROOT/ -name '*.pyc' -delete | true \
    && find /usr/lib/ -name '*.pyc' -delete | true \
    && find /var/log/ -name '*.log' -delete | true \
    && find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && rm -rf ~/.cache/ \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm
EXPOSE 8080
USER galaxy



#ENTRYPOINT ["/sbin/tini", "--"]

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy)
EXPOSE :80
#EXPOSE :21
#EXPOSE :8800
#VOLUME ["/export/", "/data/", "/var/lib/docker"]
# Autostart script that is invoked during container start
CMD ["/usr/bin/bash"]
