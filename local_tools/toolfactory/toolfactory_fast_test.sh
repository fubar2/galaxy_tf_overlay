GALAXY_URL=http://localhost:8080
GALAXY_VENV=/home/ross/rossgit/galaxytf/.venv
API_KEY="2068606201556084992"
API_KEY_USER="1286305042595563520"
# for test@bx.psu.edu user
# for sed to edit at installation
# must pass toolname outdir as cl params in that order...
# shows api keys do uncomment for debugging if you must
# echo "toolfactory_fast_test.sh: galaxy-tool-test -u $GALAXY_URL -a $API_KEY -k $API_KEY_USER -t  $1 -o  $2 --test-data $3"
galaxy-tool-test -u $GALAXY_URL -a $API_KEY -k $API_KEY_USER -t  $1 -o  $2 --test-data $3 --publish-history

