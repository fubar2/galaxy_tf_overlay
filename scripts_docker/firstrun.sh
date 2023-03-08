#!/usr/bin/env bash
# ansible command calls this to do most of the work
# no need to make this into a playbook
echo $GALAXY_VIRTUAL_ENV
service postgresql start
. $GALAXY_VIRTUAL_ENV/bin/activate
cd $GALAXY_ROOT
pip3 install -U bioblend ephemeris planemo
python3 $GALAXY_ROOT/scripts/tfsetup.py --galaxy_root $GALAXY_ROOT --force
echo "Your dev server is ready to run. \
Use GALAXY_VIRTUAL_ENV=$GALAXY_VIRTUAL_ENV/venv && sh run.sh --daemon for example. \
Local web browser url is http://localhost:8080. Admin already exists.\
Admin login is toolfactory@galaxy.org with ChangeMe! as the temporary password. \
Please do change it. Do not expose this development server on the open internet please. \
It has none of the layers of isolation that a secure public server needs."
