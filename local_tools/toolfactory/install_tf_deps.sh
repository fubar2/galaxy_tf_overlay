LOCALTOOLDIR="/home/ross/rossgit/galaxytf/local_tools"
APIK="2068606201556084992"
GAL="http://localhost:8080"
python3 -m venv .venv2
. .venv2/bin/activate
pip install ephemeris
# all unless a single id is passed in as $1
if [ -z "$1" ]; then
    for f in $LOCALTOOLDIR/*; do
        if [ -d "$f" ]; then
            TOOL=`basename "$f"`
            install_tool_deps -v -g $GAL -u "toolfactory@galaxy.org" -p "ChangeMe!" -t  $LOCALTOOLDIR/$TOOL/$TOOL.xml
        fi
   done
else
     install_tool_deps -v -g $GAL -a $APIK -t  $LOCALTOOLDIR/$1/$1.xml
fi
deactivate


