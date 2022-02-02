#!/usr/bin/env bash

GROUPID=1000
GROUPID=${USERID:-GROUPID}
set -ef -o pipefail
source _activate_current_env.sh
echo "Installing the python module mounted at /bipca"
pip install -e /bipca > pip.log
if [ "$JUPYTER" = true ] ; then
    echo "Jupyter enabled." 
else
    echo "Jupyter disabled."
    touch /etc/services.d/jupyter/down
fi
if [ "$RSTUDIO" = true ] ; then
    echo "rstudio enabled." 
else
    echo "rstudio disabled."
    touch /etc/services.d/rstudio/down
fi


exec /init sudo -u $USER -s $@ 
