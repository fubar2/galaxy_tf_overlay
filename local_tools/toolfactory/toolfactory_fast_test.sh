GALAXY_URL=http://localhost:8080
GALAXY_VENV=/home/ross/rossgit/galaxytf/venv
API_KEY="1718168589392319488"
API_KEY_USER="1810783733142353152"
# for test@bx.psu.edu user
# for sed to edit at installation
# must pass toolname outdir as cl params in that order...
. $GALAXY_VENV/bin/activate
echo "toolfactory_fast_test.sh executing galaxy-tool-test -u $GALAXY_URL -a $API_KEY -k $API_KEY_USER -t  $1 -o  $2 --publish-history  --no-history-cleanup --test-data $3"
galaxy-tool-test -u $GALAXY_URL -a $API_KEY -k $API_KEY_USER -t  $1 -o  $2 --publish-history  --no-history-cleanup --test-data $3

