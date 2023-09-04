#!/usr/bin/bash
# assume run from the git galaxy_tf_overlay clone directory
# sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null
echo "First run takes a while. Go for a walk, read the manual, or do something else more useful than watching"
OURD="../galaxytf230"
THISD=`pwd`
THISDIR=`echo "$(cd "$(dirname "$THISD")" && pwd)/$(basename "$THISD")"`
OURD="../galaxytf"
OURDIR=`realpath "$OURD"` #`echo "$(cd "$(dirname "$OURD")" && pwd)/$(basename "$OURD")"`
echo "Using thisdir = $THISDIR and ourdir = $OURDIR"
GALAXY_VIRTUAL_ENV=$OURDIR/.venv
VER="23.0"
REL="release_$VER"
RELDIR="galaxy-release_$VER"
GALZIP="https://github.com/galaxyproject/galaxy/archive/refs/heads/release_$VER.zip"
GAL_USER="ubuntu" # or whatever..this for my play server postgresql
#USE_DB_URL="postgresql:///galaxydev?host=/var/run/postgresql"
#database_connection: "postgresql:///galaxydev?host=/var/run/postgresql"
USE_DB_URL="sqlite:///$OURDIR/database/universe.sqlite?isolation_level=IMMEDIATE"
#sudo -u postgres psql -c "create role $GAL_USER with login createdb;"
#sudo -u postgres psql -c "drop database galaxydev;"
#sudo -u postgres psql -c "create database galaxydev with owner $GAL_USER;"
#sudo -u postgres psql -c "grant all privileges on database galaxydev to $GAL_USER;"

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
# mv $RELDIR/config/plugins/visualizations/* /tmp
# save building them while testing
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
sh scripts/common_startup.sh --no-create-venv
. $GALAXY_VIRTUAL_ENV/bin/activate
python3 scripts/tfsetup.py --galaxy_root $OURDIR --galaxy_venv $GALAXY_VIRTUAL_ENV --db_url $USE_DB_URL --force
# optionally - may not be wanted on a workstation :)
# sudo rm -rf /tmp/* /root/.cache/ /var/cache/* /home/$USER/.cache/ /home/$USER/.npm
echo "Your dev server is ready to run in a new directory - $OURDIR. \
Use GALAXY_VIRTUAL_ENV=$HERE/venv && sh run.sh --skip-client-build --daemon for example. \
Local web browser url is http://localhost:8080. Admin already exists. \
Admin login is toolfactory@galaxy.org with ChangeMe! as the temporary password. \
Please do change it. Do not expose this development server on the open internet please. \
It has none of the layers of isolation that a secure public server needs."
