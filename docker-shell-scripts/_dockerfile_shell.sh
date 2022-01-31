#!/bin/bash

set -ef -o pipefail

source _activate_current_env.sh
exec bash -o pipefail -c "$@"