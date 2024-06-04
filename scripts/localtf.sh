#!/usr/bin/bash
# assume run from the git galaxy_tf_overlay clone directory
echo "First run takes a while. Go for a walk, read the manual, or do something else more useful than watching"
VER="24.0.2"
REL="v$VER"
RELDIR="galaxy-$VER"
THISD=`pwd`
THISDIR=`echo "$(cd "$(dirname "$THISD")" && pwd)/$(basename "$THISD")"`
OURD="../galaxytf$VER"
GALAXY_ROOT=`realpath "$OURD"` #`echo "$(cd "$(dirname "$OURD")" && pwd)/$(basename "$OURD")"`
echo "Using thisdir = $THISDIR and ourdir = $GALAXY_ROOT"
GALAXY_VIRTUAL_ENV=$GALAXY_ROOT/.venv

export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV
GALZIP="https://github.com/galaxyproject/galaxy/archive/refs/tags/$REL.zip"
GAL_USER="ubuntu" # or whatever..this for my play server postgresql
USE_DB_URL="sqlite:///$GALAXY_ROOT/database/universe.sqlite?isolation_level=IMMEDIATE"


if [ -f "$REL.zip" ]; then
  echo "$REL.zip exists"
else
   echo "No $REL.zip Getting"
   wget -q $GALZIP
fi
if [ -d "$GALAXY_ROOT" ]; then
  echo "Deleting existing $GALAXY_ROOT"
  rm -rf $GALAXY_ROOT
fi
unzip -q -o $REL.zip
cp -rv $THISDIR/config/* $RELDIR/config/
cp -rv $THISDIR/local $RELDIR/
cp -rv $THISDIR/local_tools $RELDIR/
cp -rv $THISDIR/static/* $RELDIR/static/
cp -rv $THISDIR/scripts/* $RELDIR/scripts/
mv  $RELDIR $GALAXY_ROOT
cd $GALAXY_ROOT
VENV2=$GALAXY_ROOT/.venv2
export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV
python3 -m venv $GALAXY_VIRTUAL_ENV
TFC="tool_conf.xml,$GALAXY_ROOT/local_tools/local_tool_conf.xml"
sed -i "s~^  virtualenv:.*~  virtualenv: $GALAXY_VIRTUAL_ENV~g" $GALAXY_ROOT/config/galaxy.yml
sed -i "s~^  galaxy_root:.*~  galaxy_root: $GALAXY_ROOT~g" $GALAXY_ROOT/config/galaxy.yml
sed -i "s~^  database_connection:.*~  database_connection: $USE_DB_URL~g" $GALAXY_ROOT/config/galaxy.yml
# yes, these look redundant but they are not - for further down
sed -i "s~^  #virtualenv:.*~  virtualenv: $GALAXY_VIRTUAL_ENV~g" $GALAXY_ROOT/config/galaxy.yml
sed -i "s~^  #galaxy_root:.*~  galaxy_root: $GALAXY_ROOT~g" $GALAXY_ROOT/config/galaxy.yml
sed -i "s~^  tool_config_file:.*~  tool_config_file: $TFC~g" $GALAXY_ROOT/config/galaxy.yml
sed -i "s~^  data_dir:.*~  data_dir: $GALAXY_ROOT/database~g" $GALAXY_ROOT/config/galaxy.yml


export GALAXY_INSTALL_PREBUILT_CLIENT=1

GALAXY_INSTALL_PREBUILT_CLIENT=1 && bash $GALAXY_ROOT/scripts/common_startup.sh --no-create-venv \
  && $GALAXY_VIRTUAL_ENV/bin/galaxyctl start && sleep 20 && . $VENV2/bin/activate \
  && python3 $GALAXY_ROOT/scripts/tfsetup.py --galaxy_root $GALAXY_ROOT --galaxy_venv $GALAXY_VIRTUAL_ENV --db_url $USE_DB_URL --force 
$GALAXY_VIRTUAL_ENV/bin/galaxyctl stop
deactivate
echo "Your ToolFactory dev server is ready to run in a new directory - $GALAXY_ROOT. \
Admin login is toolfactory@galaxy.org with ChangeMe! as the temporary password. \
Please do change it. Do not expose this development server on the open internet please. \
It has none of the layers of isolation that a secure public server needs."
