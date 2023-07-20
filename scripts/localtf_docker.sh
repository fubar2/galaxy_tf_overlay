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
cp -rv $OVERLAY/config/* $GALAXY_ROOT/config/
cp -rv $OVERLAY/local $GALAXY_ROOT/
cp -rv $OVERLAY/local_tools $GALAXY_ROOT/
cp -rv $OVERLAY/static/* $GALAXY_ROOT/static/
cp -rv $OVERLAY/scripts/* $GALAXY_ROOT/scripts/
sed -i "s~^  database_connection:.*~  database_connection: $USE_DB_URL~g" $1/config/galaxy.yml
export GALAXY_VIRTUAL_ENV=$1/.venv
export GALAXY_INSTALL_PREBUILT_CLIENT=1
. $1/.venv/bin/activate
pip install -U ephemeris bioblend planemo
python3 $GALAXY_ROOT/scripts/tfsetup.py --galaxy_root $GALAXY_ROOT --galaxy_venv $GALAXY_VIRTUAL_ENV --db_url $USE_DB_URL --force

