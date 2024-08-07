#!/usr/bin/env python
import argparse
import os
import random
import secrets
import subprocess
import sys
from time import sleep
from urllib import request
from urllib.error import URLError

from bioblend import galaxy


"""

python scripts/tfsetup.py --galaxy_root ~/rossgit/galaxytf  db_url "sqlite:///<data_dir>/universe.sqlite?isolation_level=IMMEDIATE"
python scripts/tfsetup.py --galaxy_root /evol/galaxytf  db_url "postgresql:///ubuntu?host=/var/run/postgresql"

designed for simple sqlite default installation.
Workflow runs fine...
This will try to start and stop a Galaxy instance if there is not one already running.
Requires --force to rerun if admin user already exists

"""


def add_user(sa_session, security_agent, email, password, key, username):
    """
        Add Galaxy User.
        From John https://gist.github.com/jmchilton/4475646
    """
    query = sa_session.query( User ).filter_by( email=email )
    if query.count() > 0:
        print('email %s exists key=%s' % (email, key))
        return query.first()
    else:
        User.use_pbkdf2 = False
        user = User(email)
        user.username = username
        user.set_password_cleartext(password)
        sa_session.add(user)
        sa_session.flush()

        security_agent.create_private_user_role( user )
        if not user.default_permissions:
            security_agent.user_set_default_permissions( user, history=True, dataset=True )

        if key is not None:
            api_key = APIKeys()
            api_key.user_id = user.id
            api_key.key = key
            sa_session.add(api_key)
            sa_session.flush()
        return user


def run_sed(options):
    """
    eg replacement = 'APIK="%s"' % options.key
    line_start = 'APIK='
    """
    fixme = []
    # database_connection: "sqlite:///<data_dir>/universe.sqlite?isolation_level=IMMEDIATE"
    fixfile = "%s/scripts/tfextras.py" % options.galaxy_root
    fixme.append(
        (
            "GALAXY_API_KEY=",
            'GALAXY_API_KEY="%s"' % options.key,
            fixfile,
        )
    )
    fixfile = "%s/local_tools/toolfactory/toolfactory.py" % options.galaxy_root
    fixme.append(
        (
            "        self.GALAXY_ADMIN_KEY =",
            '        self.GALAXY_ADMIN_KEY = "%s"' % options.key,
            fixfile,
        )
    )
    fixme.append(
        (
            "        self.GALAXY_URL = ",
            '        self.GALAXY_URL = "%s"' % options.galaxy_url,
            fixfile,
        )
    )
    fixfile = "%s/local_tools/toolfactory/install_tf_deps.sh" % options.galaxy_root
    fixme.append(("GAL=", 'GAL="%s"' % options.galaxy_url, fixfile))
    fixme.append(("APIK=", 'APIK="%s"' % options.key, fixfile))
    fixme.append(
        (
            "LOCALTOOLDIR=",
            'LOCALTOOLDIR="%s"'
            % os.path.join(os.path.abspath(options.galaxy_root), "local_tools"),
            fixfile,
        )
    )
    fixfile = "%s/local_tools/toolfactory/localplanemotest.sh" % options.galaxy_root
    fixme.append(("GALAXY_URL=", "GALAXY_URL=%s" % options.galaxy_url, fixfile))
    fixme.append(("API_KEY=", "API_KEY=%s" % options.key, fixfile))
    fixfile = (
        "%s/local_tools/toolfactory/toolfactory_fast_test.sh" % options.galaxy_root
    )
    fixme.append(("GALAXY_URL=", "GALAXY_URL=%s" % options.galaxy_url, fixfile))
    fixme.append(("API_KEY=", "API_KEY=%s" % options.key, fixfile))
    fixme.append(("GALAXY_VENV=", "GALAXY_VENV=%s" % options.galaxy_venv, fixfile))
    fixme.append(("API_KEY_USER=", "API_KEY_USER=%s" % options.botkey, fixfile))
    for line_start, line_replacement, file_to_edit in fixme:
        cmd = [
            "sed",
            "-i",
            "s#.*%s.*#%s#g" % (line_start, line_replacement),
            file_to_edit,
        ]
        print("## executing", " ".join(cmd))
        res = subprocess.run(cmd)
        if not res.returncode == 0:
            print(
                "### Non zero %d return code from %s " % (res.returncode, "".join(cmd))
            )



"""
get_config(argv=['-c','galaxy', "--config-section","database_connection",],cwd='.')
{'db_url': 'sqlite:////home/ross/rossgit/galaxytf/config/data/universe.sqlite?isolation_level=IMMEDIATE',
'repo': None, 'config_file': '/home/ross/rossgit/galaxytf/config/galaxy.yml', 'database': 'galaxy', 'install_database_connection': None}
"""
if __name__ == "__main__":
    ALREADY = False
    apikey = "%s" % secrets.token_hex(16)
    apikey2 = "%s" % secrets.token_hex(16)
    parser = argparse.ArgumentParser(description="Create Galaxy Admin User.")
    parser.add_argument(
        "--galaxy_url", help="Galaxy server URL", default="http://localhost:8080"
    )
    parser.add_argument(
        "--galaxy_root", required=True, help="Galaxy root directory path", default="./"
    )
    parser.add_argument("--galaxy_venv", required=False, help="Galaxy venv path")
    parser.add_argument(
        "--user", help="Username - an email address.", default="toolfactory@galaxy.org"
    )
    parser.add_argument("--password", help="Password", default="ChangeMe!")
    parser.add_argument("--password2", help="Password", default=apikey2)
    parser.add_argument("--key", help="API-Key.", default=apikey)
    parser.add_argument("--botkey", help="bot API-Key.", default=apikey2)
    parser.add_argument("--username", default="tfadmin")
    parser.add_argument("--force", default=None, action="store_true")
    parser.add_argument(
        "--db_url",
        default="sqlite:///<data_dir>/universe.sqlite?isolation_level=IMMEDIATE",
    )
    parser.add_argument("args", nargs=argparse.REMAINDER)

    options = parser.parse_args()
    options.galaxy_root = os.path.abspath(options.galaxy_root)

    sys.path.insert(1, options.galaxy_root)
    sys.path.insert(1, os.path.join(options.galaxy_root, "lib"))
 
    from galaxy.model import User, APIKeys
    from galaxy.model.mapping import init
    from galaxy.model.orm.scripts import get_config

    cdb_url = get_config(
        argv=[
            "-c",
            "galaxy",
        ],
        cwd=options.galaxy_root,
    )["db_url"]
    db_url = options.db_url
    # or perhaps "postgresql:///ubuntu?host=/var/run/postgresql"
    # this is harder to please get_config(sys.argv, use_argparse=False)["db_url"]
    print("### Using db_url", cdb_url)

    mapping = init('/tmp/', cdb_url)
    sa_session = mapping.context
    security_agent = mapping.security_agent

    u = add_user(sa_session, security_agent, options.user, options.password, key=options.key, username=options.username)
    print('User = ', str(u))