#!/usr/bin/bash
# Docker version - galaxy has already been installed - so galaxy_root is the first parameter
# The overlay has also been installed so copy and run the tfsetup.py script for API keys and other installations
# This needs to be redone every time the repository is updated

if [ -n "$1" ] && [ -n "$2" ]; then
  echo "**** Using galaxy_root=$1 and overlay=$2"
else
    echo "localtf_docker.sh needs the galaxy root and the overlay root paths passed as parameters to run safely"
    exit 3
fi
GALAXY_ROOT=$1
OVERLAY=$2
USE_DB_URL="sqlite:///$1/database/universe.sqlite?isolation_level=IMMEDIATE"
cd $GALAXY_ROOT
mkdir -p $GALAXY_ROOT/database_copy $GALAXY_ROOT/local_tools_copy
cp -rv $OVERLAY/config/* $GALAXY_ROOT/config/
# cp -rv $OVERLAY/configdocker/* $GALAXY_ROOT/config # replace normal one
cp -rv $OVERLAY/local $GALAXY_ROOT/
cp -rv $OVERLAY/local_tools $GALAXY_ROOT/
cp -rv $OVERLAY/static/* $GALAXY_ROOT/static/
cp -rv $OVERLAY/scripts/* $GALAXY_ROOT/scripts/
cp -rv $GALAXY_ROOT/database/* $GALAXY_ROOT/database_copy \
cp -rv $GALAXY_ROOT/local_tools/* $GALAXY_ROOT/local_tools_copy \


TFC="tool_conf.xml,$OURDIR/local_tools/local_tool_conf.xml"
sed -i "s~^  virtualenv:.*~  virtualenv: $GALAXY_VIRTUAL_ENV~g" $OURDIR/config/galaxy.yml
sed -i "s~^  galaxy_root:.*~  galaxy_root: $OURDIR~g" $OURDIR/config/galaxy.yml
sed -i "s~^  database_connection:.*~  database_connection: $USE_DB_URL~g" $OURDIR/config/galaxy.yml
sed -i "s~^  #virtualenv:.*~  virtualenv: $GALAXY_VIRTUAL_ENV~g" $OURDIR/config/galaxy.yml
sed -i "s~^  #galaxy_root:.*~  galaxy_root: $OURDIR~g" $OURDIR/config/galaxy.yml
sed -i "s~^  tool_config_file:.*~  tool_config_file: $TFC~g" $OURDIR/config/galaxy.yml
sed -i "s~^  data_dir:.*~  data_dir: $OURDIR/database~g" $OURDIR/config/galaxy.yml


export GALAXY_VIRTUAL_ENV=$1/.venv
cd $OURDIR
export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV
export GALAXY_INSTALL_PREBUILT_CLIENT=1
GALAXY_INSTALL_PREBUILT_CLIENT=1
python3 -m venv $GALAXY_VIRTUAL_ENV
GALAXY_INSTALL_PREBUILT_CLIENT=1 && bash $OURDIR/scripts/common_startup.sh --no-create-venv
rm -rf $VENV2
python3 -m venv $VENV2
. $VENV2/bin/activate && pip install bioblend ephemeris

bash run.sh --daemon && sleep 30
. $VENV2/bin/activate && export PYTHONPATH=$GALAXY_VIRTUAL_ENV/lib/python3.10/site-packages/ \
  && python3 scripts/tfsetup.py --galaxy_root $OURDIR --galaxy_venv $GALAXY_VIRTUAL_ENV --db_url $USE_DB_URL --force
deactivate
bash run.sh --stop-daemon


#export GALAXY_INSTALL_PREBUILT_CLIENT=1
#. /tmp/venv2/bin/activate
#pip install bioblend ephemeris
#python3 $OVERLAY/scripts/tfsetup.py --galaxy_root $GALAXY_ROOT --galaxy_venv $GALAXY_VIRTUAL_ENV --db_url $USE_DB_URL --force

#VENV2=$OURDIR/.venv2
#python3 -m venv $GALAXY_VIRTUAL_ENV
## needed for 23.1 because of packaging legacy_ changes...
#GALAXY_INSTALL_PREBUILT_CLIENT=1 && bash scripts/common_startup.sh --no-create-venv
#export PYTHONPATH=
#rm -rf $VENV2
#python3 -m venv $VENV2
#. /tmp/venv2/bin/activate
#pip install -U bioblend ephemeris planemo galaxyxml
#deactivate
#cd $OURDIR
#bash run.sh --daemon && sleep 40
#echo "PYTHONPATH=PYTHONPATH:$VENV2/lib/python3.10/site-packages:$GALAXY_VIRTUAL_ENV/lib/python3.10/site-packages"
#export PYTHONPATH=PYTHONPATH:$VENV2/lib/python3.10/site-packages && \
  #python3 scripts/tfsetup.py --galaxy_root $OURDIR --galaxy_venv $GALAXY_VIRTUAL_ENV --db_url $USE_DB_URL --force
#export PYTHONPATH=
#bash run.sh --stop-daemon
