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

def run_wait_gal(url, galdir, venvdir):
    ALREADY = False
    try:
        request.urlopen(url=url)
        ALREADY = True
        print('First time - got a response on', url)
        return ALREADY
    except URLError:
        print("no galaxy yet at", url)
    ok = False
    while not ok:
        try:
            request.urlopen(url=url)
            ok = True
        except URLError:
            print("no galaxy yet at", url)
            sleep(5)
    return ALREADY


def stop_gal(url, galdir, venvdir):
    cmd = (
        "cd %s && GALAXY_VIRTUAL_ENV=%s/.venv && %s/bin/galaxyctl stop"
        % (galdir, galdir, venvdir)
    )
    print("executing", cmd)
    subprocess.run(cmd, shell=True)



def waitnojobs(gi):
    """
    sqlite problem? Race condition? Whatever.
    """
    j = gi.jobs.get_jobs()
    cjobs = [x for x in j if x["state"] in ("waiting", "running", "queued")]
    nj = len(cjobs)
    while nj > 0:
        print(cjobs)
        print(nj, "running. Waiting for zero")
        sleep(2)
        cjobs = [x for x in j if x["state"] in ("waiting", "running", "queued")]
        nj = len(cjobs)


def run_sed(options, adminkey, botkey):
    """
    eg replacement = 'APIK="%s"' % options.key
    line_start = 'APIK='
    """
    fixme = []
    # database_connection: "sqlite:///<data_dir>/universe.sqlite?isolation_level=IMMEDIATE"
    fixfile = "%s/local_tools/toolfactory/toolfactory.py" % options.galaxy_root
    fixme.append(
        (
            "        self.GALAXY_ADMIN_KEY =",
            '        self.GALAXY_ADMIN_KEY = "%s"' % adminkey,
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
    fixme.append(("APIK=", 'APIK="%s"' % adminkey, fixfile))
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
    fixme.append(("API_KEY=", "API_KEY=%s" % adminkey, fixfile))
    fixfile = (
        "%s/local_tools/toolfactory/toolfactory_fast_test.sh" % options.galaxy_root
    )
    fixme.append(("GALAXY_URL=", "GALAXY_URL=%s" % options.galaxy_url, fixfile))
    fixme.append(("API_KEY=", "API_KEY=%s" % adminkey, fixfile))
    fixme.append(("GALAXY_VENV=", "GALAXY_VENV=%s" % options.galaxy_venv, fixfile))
    fixme.append(("API_KEY_USER=", "API_KEY_USER=%s" % botkey, fixfile))
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

    apikey2 = "%s" % secrets.token_hex(16)
    apikey = "%s" % secrets.token_hex(16)

    parser = argparse.ArgumentParser(description="Add sample histories and workflows.")

    parser.add_argument("--botkey", help="bot API-Key.", default=apikey2)
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
    parser.add_argument("--key", help="API-Key.")
    parser.add_argument("--force", default=None, action="store_true")
    
    parser.add_argument("args", nargs=argparse.REMAINDER)

    options = parser.parse_args()
    options.galaxy_root = os.path.abspath(options.galaxy_root)
    ALREADY = run_wait_gal(
        url=options.galaxy_url,
        galdir=options.galaxy_root,
        venvdir=os.path.join(options.galaxy_root, ".venv"),
    )
    gi = galaxy.GalaxyInstance(url=options.galaxy_url, email="toolfactory@galaxy.org", password="ChangeMe!", verify=False)
    ulist = gi.users.get_users()
    uid = None
    for u in ulist:
        if u['email'] == "toolfactory@galaxy.org":
            uid = u['id']
            print('uid=', uid)
    adminkey = gi.users.get_user_apikey(user_id=uid)
    run_sed(options, adminkey, options.botkey)


    cmd = [
        "/usr/bin/bash",
        os.path.join(options.galaxy_root, "local_tools/toolfactory/install_tf_deps.sh"),
        "toolfactory",
    ]
    print("executing", cmd)
    subprocess.run(cmd)
    sleep(5)
    
    
    HF = os.path.join(
        options.galaxy_root, "local", "Galaxy-History-TF-samples-data.tar.gz"
    )
    try:
        hist = gi.histories.import_history(file_path=HF)
        print("hist=", str(hist))
    except Exception as E:
        print("failed to load", HF, "error=",E)
    sleep(2)
    HF = os.path.join(
        options.galaxy_root, "local", "ToolFactory-advanced_examples.tar.gz"
    )
    try:
        hist = gi.histories.import_history(file_path=HF)
        print("hist=", str(hist))
    except Exception as E:
        print("failed to load", HF, "error=",E)
    sleep(2)
    WF = os.path.join(
        options.galaxy_root, "local", "Galaxy-Workflow-TF_sample_workflow.ga"
    )
    try:
        wfr = gi.workflows.import_workflow_from_local_path(
            file_local_path=WF, publish=True
        )
        print("import", WF, "Returned", wfr)
    except Exception as E:
        print("failed to load", WF, "error=",E)
    sleep(2)
    WF = os.path.join(
        options.galaxy_root, "local", "Galaxy-Workflow_Advanced_ToolFactory_examples.ga"
    )
    try:
        wfr = gi.workflows.import_workflow_from_local_path(
            file_local_path=WF, publish=True
        )
        print("import", WF, "Returned", wfr)
    except Exception as E:
        print("failed to load", WF, "error=",E)
    sleep(5)
