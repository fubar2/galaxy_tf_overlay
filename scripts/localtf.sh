!/usr/bin/bash
echo "First run takes a while. Go for a walk or do something else more useful than watching\
Warning: the ubuntu database in your local postgres server will be destroyed and recreated if it already exists."
REL="release_23.0"
GALZIP="https://github.com/galaxyproject/galaxy/archive/refs/heads/$REL.zip"
wget $GALZIP
unzip $REL.zip -d galaxytf
cd galaxytf
mv galaxy-$REL/* .
rm -rf galaxy-$REL
sudo apt install postgresql-14

git clone --depth 1 https://github.com/fubar2/galaxy_tf_overlay
cp -rvu galaxy_tf_overlay/* ./
sudo -u postgres psql -c "create role $USER if not exists;"
sudo -u postgres psql -c "drop database galaxydev if exists;"
sudo -u postgres psql -c "create database galaxydev;"
sudo -u postgres psql -c "grant all privileges on database galaxydev to $USER;"

# now have a fresh clone with the TF configuration files in place or your local mods
# using git is painful because we mess with the repository and common-startup.sh checks HEAD
# for the client build hash in a way that fails :(

HERE=`pwd`
export GALAXY_GRAVITY_STATE_DIR=$HERE/database
export NODE_PATH=$HERE/venv/lib/node_modules
export NODE_VIRTUAL_ENV=$HERE/venv
export NPM_CONFIG_PREFIX=$HERE/venv
GALAXY_VIRTUAL_ENV=$HERE/venv
export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV
echo $GALAXY_VIRTUAL_ENV
python3 -m venv $GALAXY_VIRTUAL_ENV
GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV && sh scripts/common_startup.sh --no-create-venv
. venv/bin/activate
pip3 install bioblend ephemeris planemo
GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV && python3 scripts/tfsetup.py --galaxy_root $HERE
echo "Your dev server is ready to run. \
Use GALAXY_VIRTUAL_ENV=$HERE/venv && sh run.sh --skip-client-build --daemon for example. \
Local web browser url is http://localhost:8080. Admin already exists.\
Admin login is toolfactory@galaxy.org with ChangeMe! as the temporary password. \
Please do change it. \
Do not expose this development server on the open internet please.
It has none of the layers of isolation that a secure public server needs."





