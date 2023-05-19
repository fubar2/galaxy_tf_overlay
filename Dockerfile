# Base Image
FROM ubuntu:latest
# Metadata
LABEL base_image="biocontainers/biocontainers:vdebian-buster-backports_cv1"
LABEL version="3"
LABEL software="ToolFactory"
LABEL software.version="20201112"
LABEL about.summary="Galaxy tool to make and test new tools"
LABEL about.home="https://github.com/fubar2/toolfactory-biodocker"
LABEL about.documentation="https://github.com/fubar2/toolfactory"
LABEL about.license="GPL3"
LABEL about.license_file="/usr/share/common-licenses/GPL3"
LABEL about.tags="Galaxy Tool Builders"
LABEL extra.identifiers.biotools=toolfactory
# Maintainer
MAINTAINER Ross Lazarus <ross.lazarus@gmail.com>
USER root
ENV GALAXY_USER="galaxy" \
 REL="v23.0" \
 RELDIR="galaxy-23.0" \
 ORELDIR="galaxy_tf_overlay-main" \
 GALZIP="https://github.com/galaxyproject/galaxy/archive/refs/tags/v23.0.zip" \
 USE_DB_URL="sqlite:///$OURDIR/database/universe.sqlite?isolation_level=IMMEDIATE" \
 GALAXY_VIRTUAL_ENV="/galaxytf/.venv" \
 GALAXY_UID=1450 \
 GALAXY_GID=1450 \
 GALAXY_HOME="/galaxytf" \
 OVERLAY_HOME="/galaxy_tf_overlay" \
 OVERLAY_ZIP="https://github.com/fubar2/galaxy_tf_overlay/archive/refs/heads/main.zip"
RUN apt-get update \
&& apt-get install -y python3 python3-venv python3-pip python3-wheel wget unzip nano git nodeenv
RUN wget $OVERLAY_ZIP -O /tmp/overlay.zip \
&& unzip /tmp/overlay.zip -d /tmp \
&& rm -rf $OVERLAY_HOME \
&& mkdir -p $OVERLAY_HOME \
&& cp -rv /tmp/$ORELDIR/* $OVERLAY_HOME/ \
&& wget $GALZIP -O /tmp/gal.zip \
&& mkdir -p $GALAXY_HOME \
&& unzip /tmp/gal.zip -d /tmp && rm -rf $GALAXY_HOME/* \
&& cp -rv /tmp/$RELDIR/* $GALAXY_HOME/ \
&& cp -rvu $OVERLAY_HOME/config/* $GALAXY_HOME/config/ \
&& cp -rvu $OVERLAY_HOME/local $GALAXY_HOME/ \
&& cp -rvu $OVERLAY_HOME/local_tools $GALAXY_HOME/ \
&& cp -rvu $OVERLAY_HOME/static/* $GALAXY_HOME/static/ \
&& cp -rvu $OVERLAY_HOME/scripts/* $GALAXY_HOME/scripts/ \
&& rm -rf /tmp/$RELDIR  /tmp/$ORELDIR \
&& python3 -m venv $GALAXY_HOME/.venv  \
&& . $GALAXY_HOME/.venv/bin/activate \
&& sed -i "s#.*  database_connection:.*#  database_connection: $USE_DB_URL#g" $GALAXY_HOME/config/galaxy.yml \
&& python3 -m venv $GALAXY_VIRTUAL_ENV

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID \
&& adduser --system --quiet --home /home/galaxy --uid $GALAXY_UID --gid $GALAXY_GID --shell /usr/bin/bash $GALAXY_USER \
&& mkdir -p $GALAXY_HOME \
&& chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME


USER $GALAXY_USER
RUN cd $GALAXY_HOME && bash $GALAXY_HOME/scripts/common_startup.sh --no-create-venv \
&& . $GALAXY_VIRTUAL_ENV/bin/activate \
&& $GALAXY_VIRTUAL_ENV/bin/python3 $GALAXY_HOME/scripts/tfsetup.py --galaxy_root $GALAXY_HOME --galaxy_venv $GALAXY_VIRTUAL_ENV --db_url $USE_DB_URL --force
USER root
RUN find /galaxytf -name '*.pyc' -delete | true \
&& find /usr/lib/ -name '*.pyc' -delete | true \
&& find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
&& rm -rf $OVERLAY_HOME /tmp/* /root/.cache/ /var/cache/* $GALAXY_HOME/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/$USER/.cache/ /home/$USER/.npm

EXPOSE 8080
USER galaxy
WORKDIR $GALAXY_HOME

ENTRYPOINT ["/sbin/tini", "--"]

# Autostart script that is invoked during container start
CMD ["/usr/bin/sh", "$GALAXY_HOME/run.sh"]
