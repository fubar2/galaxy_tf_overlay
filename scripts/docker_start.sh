#!/usr/bin/sh
FILE=/work/galaxytf/database/universe.sqlite
echo "checking $FILE"
if ! [ -f "$FILE" ]; then
    echo "$FILE not found. Filling"
    cp -rv /work/galaxytf/database_copy/* /work/galaxytf/database/
    cp -rv /work/galaxytf/local_tools_copy/* /work/galaxytf/local_tools/
    chown -R galaxy:galaxy /work/galaxytf/database /work/galaxytf/local_tools
fi
#rm -rf /work/galaxytf/database_copy /work/galaxytf/local_tools_copy
cd /work/galaxytf
/usr/bin/sh /work/galaxytf/run.sh
