#!/usr/bin/bash
useme="release_23.1"
echo "First run takes a while. Go for a walk or do something else more useful than watching"
git clone https://github.com/galaxyproject/galaxy.git galaxytf
cd galaxytf
git checkout $USEME
# know to work: 27cd9bb68b45175fc724e4d233aedf43bbd5f059
git clone --depth 1 https://github.com/fubar2/galaxy_tf_overlay
cp -rvu galaxy_tf_overlay/* ./
# now have a fresh clone with the TF configuration files in place
HERE=`pwd`
GRAVITY_STATE_DIR=$HERE/database
NODE_PATH=$HERE/venv/lib/node_modules
NODE_VIRTUAL_ENV=$HERE/venv
NPM_CONFIG_PREFIX=$HERE/venv
GALAXY_VIRTUAL_ENV=$HERE/venv
export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV
echo $GALAXY_VIRTUAL_ENV
python3 -m venv $GALAXY_VIRTUAL_ENV
sh scripts/common_startup.sh --no-create-venv
. venv/bin/activate
pip3 install bioblend ephemeris planemo
python3 scripts/tfsetup.py --galaxy_root $HERE
echo "Your dev server is ready to run. \
Use GALAXY_VIRTUAL_ENV=$HERE/venv && sh run.sh --skip-client-build --daemon for example. \
Local web browser url is http://localhost:8080. Admin already exists.\
Admin login is toolfactory@galaxy.org with ChangeMe! as the temporary password. \
Please do change it. Do not expose this development server on the open internet please.
It has none of the layers of isolation that a secure public server needs."
