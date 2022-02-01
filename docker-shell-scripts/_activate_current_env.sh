#!/bin/bash

# This script should never be called directly, only sourced:

#     source _activate_current_env.sh


# Initialize the current shell
# eval "$(CONDA_PREFIX=/_invalid "${CONDA_EXE}" shell hook --shell=bash)"
# # Note: adding "MAMBA_ROOT_PREFIX=/_invalid" is an ugly temporary workaround
# # for <https://github.com/mamba-org/mamba/issues/1322>.
CONDA_BASE=$(conda info --base) ; 
source $CONDA_BASE/etc/profile.d/conda.sh
# # For robustness, try all possible activate commands.
conda activate "bipca-experiment"
