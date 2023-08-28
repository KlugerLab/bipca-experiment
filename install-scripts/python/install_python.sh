#!/usr/bin/env bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
conda update -n base conda
conda install -n base conda-libmamba-solver
conda config --set solver libmamba

