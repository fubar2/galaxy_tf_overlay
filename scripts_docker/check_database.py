#!/usr/bin/env python

# This script checks if the database is connected by querying an user

import sys
sys.path.insert(1,'/galaxy-central')
sys.path.insert(1,'/galaxy-central/lib')

from galaxy.model import User
from galaxy.model.mapping import init
from galaxy.model.orm.scripts import get_config
import argparse

__author__ = "Lukas Voegtle"
__email__ = "voegtlel@tf.uni-freiburg.de"

if __name__ == "__main__":
    db_url = get_config(sys.argv)['db_url']
    mapping = init('/tmp/', db_url)
    sa_session = mapping.context
    security_agent = mapping.security_agent

    # Just query something
    query = sa_session.query(User).filter_by(email="toolfactory@galaxy.org")
    query.count()
