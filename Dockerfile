# Galaxy 23.0 in docker-galaxy-unstable
# Please do not ever expose this development server on the open internet.
# includes a ToolFactory - a Galaxy tool to generate and test new Galaxy tools
# The ToolFactory always starts with the same sample history and workflow built in
# Login as toolfactory@galaxy.org using the password 'ChangeMe!'.
# Only an administrative user can run the ToolFactory - anon and ordinary users cannot.
# Most of the infrastructure is copied directly from Bjoern Gruening's docker-galaxy-stable and
# has been hacked to work with the current dev 23.0
# Note that nginx, proftpd, tus, cvmfs, condor....etc are not installed because this is supposed to be a throw-away dev server
# Recommended command line is something like docker run -d -p 8080:8080 -v /evol/export:/export fubar2:toolfactory_docker
# The exported directory maintains persistence between docker image runs and can be
# deleted when no longer needed provided you have made copies of histories containing the jobs for any useful tools
# you have generated...

FROM phusion/baseimage:jammy-1.0.1
MAINTAINER ross dot lazarus at gmail period com

ARG PGV=14 \
        BUILD_DIR=/tf_build  \
        REL=release_23.0 \
        GALAXY_ROOT=/galaxy-central \
        GALAXY_USER=galaxy \
        EXPORT_DIR=/export \
        GALAXY_VIRTUAL_ENV=$GALAXY_ROOT/.venv \
        GALAXY_CONDA_PREFIX=$GALAXY_ROOT/_conda

# use args for things needed to construct ENV strings

ENV DEBIAN_FRONTEND=noninteractive \
        GALAXY_ROOT=$GALAXY_ROOT \
        GALAXY_USER=$GALAXY_USER \
        GALAXY_HOME=/home/$GALAXY_USER \
        EXPORT_DIR=$EXPORT_DIR \
        GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV \
        GALZIP="https://github.com/galaxyproject/galaxy/archive/refs/heads/$REL.zip" \
        GALAXY_CONFIG_BRAND="ToolFactory Docker" \
        GALAXY_CONFIG_TOOL_CONFIG_FILE="tool_conf.xml,/galaxy-central/local_tools/local_tool_conf.xml" \
        GALAXY_CONFIG_ADMIN_USERS="admin@galaxy.org,toolfactory@galaxy.org" \
        GALAXY_UID=1450 \
        GALAXY_GID=1450 \
        GALAXY_POSTGRES_UID=1550 \
        GALAXY_POSTGRES_GID=1550 \
        GALAXY_LOGS_DIR=$GALAXY_ROOT/logs \
        PG_VERSION=$PGV \
        PG_DATA_DIR_DEFAULT=/var/lib/postgresql/$PGV/main \
        PG_CONF_DIR_DEFAULT=/etc/postgresql/$PGV/main \
        PG_DATA_DIR_HOST=$EXPORT_DIR/postgresql/$PGV/main

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y -qq --no-install-recommends locales tzdata openssl netbase apt-utils apt-transport-https unzip supervisor \
        software-properties-common ca-certificates curl python3-dev gcc python3-pip build-essential python3-venv \
        python3-wheel nano wget git python3-setuptools gnupg mercurial lsb-release sudo \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && dpkg-reconfigure -f noninteractive tzdata \
    && groupadd -r postgres -g $GALAXY_POSTGRES_GID \
    && adduser --system --quiet --shell /usr/bin/bash --home /var/lib/postgresql --no-create-home --uid $GALAXY_POSTGRES_UID --gid $GALAXY_POSTGRES_GID postgres \
    && groupadd -r $GALAXY_USER -g $GALAXY_GID \
    && adduser --system --quiet --home /home/galaxy --uid $GALAXY_UID --gid $GALAXY_GID --shell /usr/bin/bash $GALAXY_USER \
    && mkdir -p $EXPORT_DIR $GALAXY_HOME  $GALAXY_ROOT/logs \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME $EXPORT_DIR $GALAXY_LOGS_DIR \
    && groupadd -f docker \
    && usermod -aG docker $GALAXY_USER \
    && mkdir -p $GALAXY_ROOT  \
    && mkdir -p $BUILD_DIR \
    && cd $BUILD_DIR \
    && git clone --depth 1 https://github.com/fubar2/galaxy_tf_overlay.git \
    && wget $GALZIP \
    && unzip $REL.zip \
    && mv $BUILD_DIR/galaxy-$REL/* $GALAXY_ROOT/  \
    && cd $GALAXY_ROOT \
    && cp -rv $BUILD_DIR/galaxy_tf_overlay/* $GALAXY_ROOT/  \
    && rm -rf $BUILD_DIR \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get -y update \
    && apt-get install -y docker-ce-cli docker-ce containerd.io docker-compose-plugin \
    && printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d \
    && apt-get install -y postgresql-$PGV \
    && python3 -m venv $GALAXY_VIRTUAL_ENV \
    && su postgres -c '/usr/bin/psql -c "create role galaxy with login createdb;"' \
    && su postgres -c '/usr/bin/psql -c "DROP DATABASE IF EXISTS galaxydev;"' \
    && su postgres -c '/usr/bin/psql -c "create database galaxydev;"' \
    && su postgres -c '/usr/bin/psql -c  "grant all privileges on database galaxydev to galaxy;"' \
    && chown -R galaxy:galaxy $GALAXY_ROOT $GALAXY_VIRTUAL_ENV  /home/galaxy \
    && service postgresql stop

RUN curl -s -L https://repo.anaconda.com/miniconda/Miniconda3-4.7.10-Linux-x86_64.sh > ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p $GALAXY_CONDA_PREFIX/ \
    && rm ~/miniconda.sh \
    && ln -s $GALAXY_CONDA_PREFIX/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". $GALAXY_CONDA_PREFIX/etc/profile.d/conda.sh" >> $GALAXY_HOME/.bashrc \
    && echo "conda activate base" >> $GALAXY_HOME/.bashrc \
    && export PATH=$GALAXY_CONDA_PREFIX/bin/:$PATH \
    && conda config --add channels defaults \
    && conda config --add channels bioconda \
    && conda config --add channels conda-forge \
    && conda install virtualenv pip ephemeris \
    && chown $GALAXY_USER:$GALAXY_USER -R /tool_deps/ /etc/profile.d/conda.sh \
    && conda clean --packages -t -i \
    # cleanup dance
    && find $GALAXY_ROOT -name '*.pyc' -delete | true \
    && find /usr/lib/ -name '*.pyc' -delete | true \
    && find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm

ADD config_docker/galaxy.yml $GALAXY_ROOT/config/galaxy.yml
ADD scripts_docker/check_database.py /usr/local/bin/check_database.py
ADD scripts_docker/export_user_files.py /usr/local/bin/export_user_files.py
ADD scripts_docker/startuptf.sh /usr/bin/startup
ADD config_docker/galaxy.conf /etc/supervisor/conf.d/galaxy.conf
ADD config_docker/post-start-actions.sh /export/post-start-actions.sh
ADD config_docker/job_conf.xml $GALAXY_ROOT/config/job_conf.xml
ADD config/tool_conf.xml $GALAXY_ROOT/config/tool_conf.xml
ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini /sbin/tini


RUN cd $GALAXY_ROOT \
    && . $GALAXY_VIRTUAL_ENV/bin/activate \
    && mv $GALAXY_ROOT/config/plugins/visualizations $GALAXY_ROOT/config/plugins/visualizations_copy \
    && mkdir $GALAXY_ROOT/config/plugins/visualizations \
    && su galaxy -c "/usr/bin/bash $GALAXY_ROOT/scripts/common_startup.sh --no-create-venv" \
    && su  galaxy -c "$GALAXY_VIRTUAL_ENV/bin/galaxyctl -c $GALAXY_ROOT/config/galaxy.yml update" \
    && su galaxy -c "/usr/bin/bash $GALAXY_ROOT/manage_db.sh init" \
    # && su  galaxy -c "/usr/bin/bash $GALAXY_ROOT/manage_db.sh upgrade" \
    && chown -R galaxy:galaxy $GALAXY_ROOT


RUN chmod a+x /sbin/tini /usr/local/bin/*.py  /export/post-start-actions.sh /usr/bin/startup \
    && find $GALAXY_ROOT/ -name '*.pyc' -delete | true \
    && find /usr/lib/ -name '*.pyc' -delete | true \
    && find /var/log/ -name '*.log' -delete | true \
    && find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && rm -rf ~/.cache/ \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm \
     /root/.cache/ /root/.npm

EXPOSE :8080

ENV SUPERVISOR_POSTGRES_AUTOSTART=True \
    SUPERVISOR_MANAGE_POSTGRES=True \
    SUPERVISOR_MANAGE_CRON=True \
    SUPERVISOR_MANAGE_PROFTP=False \
    SUPERVISOR_MANAGE_REPORTS=False \
    SUPERVISOR_MANAGE_IE_PROXY=False \
    SUPERVISOR_MANAGE_CONDOR=False \
    SUPERVISOR_MANAGE_SLURM= \
    HOST_DOCKER_LEGACY= \
    STARTUP_EXPORT_USER_FILES=True

ENTRYPOINT ["/sbin/tini", "--"]

# Autostart script that is invoked during container start
#CMD ["/usr/bin/startup"]
CMD ["/usr/bin/bash"]
