# ansible command calls this to do most of the work
# no need to make this into playbooks
HERE=`pwd`
echo "$HERE"
export GRAVITY_STATE_DIR=$HERE/database
export NODE_PATH=$HERE/venv/lib/node_modules
export NODE_VIRTUAL_ENV=$HERE/venv
export NPM_CONFIG_PREFIX=$HERE/venv
export GALAXY_VIRTUAL_ENV=$HERE/venv
GALAXY_VIRTUAL_ENV=$HERE/venv
echo $GALAXY_VIRTUAL_ENV
python3 -m venv $GALAXY_VIRTUAL_ENV
git clone https://github.com/galaxyproject/galaxy.git
mv galaxy/* $HERE
rm -rf galaxy
git checkout release_23.0
# know to work: 27cd9bb68b45175fc724e4d233aedf43bbd5f059
git clone --depth 1 https://github.com/fubar2/galaxy_tf_overlay.git
cp -rvu galaxy_tf_overlay/* ./

sh scripts/common_startup.sh --no-create-venv
. venv/bin/activate
pip3 install bioblend ephemeris planemo
git clone
python3 scripts/tfsetup.py --galaxy_root $HERE
echo "Your dev server is ready to run. \
Use GALAXY_VIRTUAL_ENV=$HERE/venv && sh run.sh --skip-client-build --daemon for example. \
Local web browser url is http://localhost:8080. Admin already exists.\
Admin login is toolfactory@galaxy.org with ChangeMe! as the temporary password. \
Please do change it. Do not expose this development server on the open internet please.
It has none of the layers of isolation that a secure public server needs."
