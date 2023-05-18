#!/usr/bin/bash
# assume run from the git galaxy_tf_overlay clone directory
# sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null

echo "First run takes a while. Go for a walk, read the manual, or do something else more useful than watching"
USER="ubuntu" # or whatever..this for my play server
USEDBURL="postgresql:///$USER?host=/var/run/postgresql"
sudo -u postgres psql -c "create role $USER with login createdb;"
sudo -u postgres psql -c "drop database galaxydev;"
sudo -u postgres psql -c "create database galaxydev;"
sudo -u postgres psql -c "grant all privileges on database galaxydev to $USER;"
OURDIR="../galaxytf"

REL="release_23.0"
GALZIP="https://github.com/galaxyproject/galaxy/archive/refs/heads/$REL.zip"
if [ -f "$REL.zip" ]; then
  echo "$REL.zip exists"
else
   echo "No $REL.zip. Getting"
   wget $GALZIP
fi
if [ -d "$OURDIR" ]; then
  echo "Deleting existing $OURDIR"
  rm -rf $OURDIR
fi
unzip $REL.zip
mv  galaxy-$REL $OURDIR
cd $OURDIR
cp -rvu ../galaxy_tf_overlay/* ./
cp ../galaxy_tf_overlay/local_tools/local_tool_config.xml ./config
sed -i "s#.*  database_connection:.*#  database_connection:  $USEDBURL#g" $OURDIR/config/galaxy.yml
GALAXY_VIRTUAL_ENV=$OURDIR/.venv
echo $GALAXY_VIRTUAL_ENV
python3 -m venv $GALAXY_VIRTUAL_ENV
export GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV && sh scripts/common_startup.sh --no-create-venv
. $GALAXY_VIRTUAL_ENV/bin/activate
pip3 install -U bioblend ephemeris planemo watchdog
python3 scripts/tfsetup.py --galaxy_root $OURDIR --galaxy_venv $GALAXY_VIRTUAL_ENV
find $OURDIR -name '*.pyc' -delete | true \
find /usr/lib/ -name '*.pyc' -delete | true \
find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
rm -rf /tmp/* /root/.cache/ /var/cache/* $OURDIR/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/$USER/.cache/ /home/$USER/.npm

echo "Your dev server is ready to run. \
Use GALAXY_VIRTUAL_ENV=$HERE/venv && sh run.sh --skip-client-build --daemon for example. \
Local web browser url is http://localhost:8080. Admin already exists.\
Admin login is toolfactory@galaxy.org with ChangeMe! as the temporary password. \
Please do change it. Do not expose this development server on the open internet please. \
It has none of the layers of isolation that a secure public server needs."

