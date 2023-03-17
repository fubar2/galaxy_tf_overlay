#!/usr/bin/env bash
USER="galaxy" # or whatever..this for my play server
sudo -u postgres psql -c "create role $USER with login createdb;"
sudo -u postgres psql -c "drop database galaxydev;"
sudo -u postgres psql -c "create database galaxydev;"
sudo -u postgres psql -c "grant all privileges on database galaxydev to $USER;"
echo $GALAXY_VIRTUAL_ENV
. $GALAXY_VIRTUAL_ENV/bin/activate
cd $GALAXY_ROOT
sudo -u galaxy /usr/local/bash /galaxy-central/manage_db.sh init
python3 $GALAXY_ROOT/scripts/tfsetup.py --galaxy_root $GALAXY_ROOT --galaxy_venv $GALAXY_VIRTUAL_ENV --force
echo "Your dev server is ready to run. \
Use GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV/venv && sh run.sh --daemon for example. \
Local web browser url is http://localhost:8080. Admin already exists.\
Admin login is toolfactory@galaxy.org with ChangeMe! as the temporary password. \
Please do change it. Do not expose this development server on the open internet please. \
It has none of the layers of isolation that a secure public server needs."
