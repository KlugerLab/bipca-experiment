#!/bin/bash
## taken from https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_tidyverse.sh
## assumes that littler is installed, r is in the path, and install2.r is in the path
set -e
## build ARGs
NCPUS=${NCPUS:--1}



install2.r --error --skipinstalled -n $NCPUS \
    tidyverse \
    devtools \
    rmarkdown \
    BiocManager \
    vroom \
    gert

## dplyr database backends
install2.r --error --skipmissing --skipinstalled -n $NCPUS \
    arrow \
    dbplyr \
    DBI \
    dtplyr \
    duckdb \
    nycflights13 \
    Lahman \
    RMariaDB \
    RPostgres \
    RSQLite \
    fst

## a bridge to far? -- brings in another 60 packages
# install2.r --error --skipinstalled -n $NCPUS tidymodels

 rm -rf /tmp/downloaded_packages