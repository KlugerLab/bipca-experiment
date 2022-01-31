#!/usr/bin/env bash
# exec /docker/install_jupyter_service.sh
# exec pip install -e /bipca 
set -ef -o pipefail
source _activate_current_env.sh
pip install -e /bipca
if [ "$JUPYTER" = true ] ; then
    echo "Jupyter enabled." 
else
    touch /etc/services.d/jupyter/down
fi
if [ "$RSTUDIO" = true ] ; then
    echo "rstudio enabled." 
else
    touch /etc/services.d/rstudio/down
fi
exec /init sudo -E -u $USER -s $@ 
