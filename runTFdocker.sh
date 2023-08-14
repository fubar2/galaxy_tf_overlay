#!/usr/bin/env bash
# docker run -i -p 8080:8080 -v ~/rossgit/galaxy_tf_overlay/external/database:/work/galaxytf/database/ -v ~/rossgit/galaxy_tf_overlay/external/local_tools:/work/galaxytf/local_tools/ quay.io/fubar2/galaxy_toolfactory:latest
docker run -d -p 8080:8080 -v ~/rossgit/galaxy_tf_overlay/external/database:/work/galaxytf/database/ -v ~/rossgit/galaxy_tf_overlay/external/local_tools:/work/galaxytf/local_tools/ quay.io/fubar2/galaxy_toolfactory:latest
