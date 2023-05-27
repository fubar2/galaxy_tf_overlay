#!/usr/bin/bash
# Docker version - galaxy has already been installed - so galaxy_root is the first parameter
# assume run from the git galaxy_tf_overlay clone directory
GALAXY_ROOT=$1
OVERLAY=$1/galaxy_tf_overlay-main
echo "Using galaxy_root = $GALAXY_ROOT"
GAL_USER="galaxy" # or whatever..this for my play server postgresql
USE_DB_URL="sqlite:///$GALAXY_ROOT/database/universe.sqlite?isolation_level=IMMEDIATE"
cd $GALAXY_ROOT

# mkdir -p $GALAXY_ROOT/config/plugins/notinusenowvisualizations/
# mv $GALAXY_ROOT/config/plugins/visualizations/* $GALAXY_ROOT/config/plugins/notinusenowvisualizations/
# save building them while testing

cp -rv $OVERLAY/config/* $GALAXY_ROOT/config/
cp -rv $OVERLAY/local $GALAXY_ROOT/
cp -rv $OVERLAY/local_tools $GALAXY_ROOT/
cp -rv $OVERLAY/static/* $GALAXY_ROOT/static/
cp -rv $OVERLAY/scripts/* $GALAXY_ROOT/scripts/

sed -i "s#.*  database_connection:.*#  database_connection: $USE_DB_URL#g" $GALAXY_ROOT/config/galaxy.yml
GALAXY_VIRTUAL_ENV=$GALAXY_ROOT/.venv
export GALAXY_VIRTUAL_ENV=$GALAXY_ROOT/.venv
. $GALAXY_VIRTUAL_ENV/bin/activate
pip3 install -U bioblend ephemeris planemo galaxyxml
python3 $GALAXY_ROOT/scripts/tfsetup.py --galaxy_root $GALAXY_ROOT --galaxy_venv $GALAXY_VIRTUAL_ENV --db_url $USE_DB_URL --force
find $GALAXY_ROOT -name '*.pyc' -delete | true
find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true

