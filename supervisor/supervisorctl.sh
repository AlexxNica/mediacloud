#!/bin/bash

# PYTHONHOME might have been set by run_in_env.sh to make use of Media Cloud's
# virtualenv. Supervisor doesn't support Python 3, to unset
# PYTHONHOME for Supervisor's Python 2.7 to search for modules at correct
# location.
unset PYTHONHOME

/usr/local/bin/supervisorctl \
    --configuration `dirname "$0"`/supervisord.conf \
    --serverurl http://localhost:8398 \
    --username supervisord \
    --password qHujfp7n4J \
    $*
