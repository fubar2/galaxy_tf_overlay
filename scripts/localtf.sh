#!/usr/bin/bash
# assume run from the git galaxy_tf_overlay clone directory
echo "First run takes a while. Go for a walk, read the manual, or do something else more useful than watching"
OURD="../galaxytf231"
THISD=`pwd`
THISDIR=`echo "$(cd "$(dirname "$THISD")" && pwd)/$(basename "$THISD")"`
OURD="../galaxytf231"
OURDIR=`realpath "$OURD"` #`echo "$(cd "$(dirname "$OURD")" && pwd)/$(basename "$OURD")"`
echo "Using thisdir = $THISDIR and ourdir = $OURDIR"
GALAXY_VIRTUAL_ENV=$OURDIR/.venv
VER="23.1"
REL="release_$VER"
RELDIR="galaxy-release_$VER"
GALZIP="https://github.com/galaxyproject/galaxy/archive/refs/heads/release_$VER.zip"
GAL_USER="ubuntu" # or whatever..this for my play server postgresql
USE_DB_URL="sqlite:///$OURDIR/database/universe.sqlite?isolation_level=IMMEDIATE"

if [ -f "$REL.zip" ]; then
  echo "$REL.zip exists"
else
   echo "No $REL.zip Getting"
   wget -q $GALZIP
fi
if [ -d "$OURDIR" ]; then
  echo "Deleting existing $OURDIR"
  rm -rf $OURDIR
fi
unzip -q -o $REL.zip
cp -rv $THISDIR/config/* $RELDIR/config/
cp -rv $THISDIR/local $RELDIR/
cp -rv $THISDIR/local_tools $RELDIR/
cp -rv $THISDIR/static/* $RELDIR/static/
cp -rv $THISDIR/scripts/* $RELDIR/scripts/
mv  $RELDIR $OURDIR
cd $OURDIR

TFC="tool_conf.xml,$OURDIR/local_tools/local_tool_conf.xml"
sed -i "s~^  virtualenv:.*~  virtualenv: $GALAXY_VIRTUAL_ENV~g" $OURDIR/config/galaxy.yml
sed -i "s~^  galaxy_root:.*~  galaxy_root: $OURDIR~g" $OURDIR/config/galaxy.yml
sed -i "s~^  database_connection:.*~  database_connection: $USE_DB_URL~g" $OURDIR/config/galaxy.yml
sed -i "s~^  #virtualenv:.*~  virtualenv: $GALAXY_VIRTUAL_ENV~g" $OURDIR/config/galaxy.yml
sed -i "s~^  #galaxy_root:.*~  galaxy_root: $OURDIR~g" $OURDIR/config/galaxy.yml
sed -i "s~^  tool_config_file:.*~  tool_config_file: $TFC~g" $OURDIR/config/galaxy.yml
sed -i "s~^  data_dir:.*~  data_dir: $OURDIR/database~g" $OURDIR/config/galaxy.yml

export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV
export GALAXY_INSTALL_PREBUILT_CLIENT=1
GALAXY_INSTALL_PREBUILT_CLIENT=1
python3 -m venv $GALAXY_VIRTUAL_ENV
# needed for 23.1 because of packaging legacy_ changes...
GALAXY_INSTALL_PREBUILT_CLIENT=1 && sh scripts/common_startup.sh --no-create-venv
rm -rf /tmp/venv2
cp -r $GALAXY_VIRTUAL_ENV /tmp/venv2
. /tmp/venv2/bin/activate
pip install -U bioblend ephemeris
python3 scripts/tfsetup.py --galaxy_root $OURDIR --galaxy_venv $GALAXY_VIRTUAL_ENV --db_url $USE_DB_URL --force
deactivate
echo "Your dev server is ready to run in a new directory - $OURDIR. \
Use GALAXY_VIRTUAL_ENV=$HERE/venv && sh run.sh --skip-client-build --daemon for example. \
Local web browser url is http://localhost:8080. Admin already exists. \
Admin login is toolfactory@galaxy.org with ChangeMe! as the temporary password. \
Please do change it. Do not expose this development server on the open internet please. \
It has none of the layers of isolation that a secure public server needs."
