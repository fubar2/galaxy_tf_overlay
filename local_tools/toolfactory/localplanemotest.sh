# pass path to tool as parameter /work/galaxytf/local_tools/tacrev/tacrev.xml
GALAXY_URL=http://localhost:8080
API_KEY="43011375138414336"
# for test@bx.psu.edu user
# for sed to edit at installation
planemo test --galaxy_admin_key $API_KEY --engine external_galaxy --galaxy_url $GALAXY_URL --update_test_data $1
