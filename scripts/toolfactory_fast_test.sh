GALAXY_URL=http://localhost:8080
GALAXY_VENV=/home/ross/rossgit/galaxytf/venv
APIK="1566388550637562880"
UAPIK="43435a292a45bb903ab78ca005a74cd2"
# for test@bx.psu.edu user
# for sed to edit at installation
# must pass toolname outdir as cl params in that order...
. $GALAXY_VENV/bin/activate
echo "toolfactory_fast_test.sh executing VERBOSE_ERRORS=1 && UPLOAD_ASYNC=1 && galaxy-tool-test -u $GALAXY_URL -a $APIK  -k $UAPIK -t  $1 -o  $2 --publish-history  --no-history-cleanup --test-data $3"
#galaxy-tool-test -u $GALAXY_URL -a $APIK -k $UAPIK -t  $1 -o  $2 --publish-history  --no-history-cleanup --test-data $3
VERBOSE_ERRORS=1 && UPLOAD_ASYNC=1 && galaxy-tool-test -u $GALAXY_URL -a $APIK  -k $UAPIK -t  $1 -o  $2 --publish-history  --no-history-cleanup --test-data $3
