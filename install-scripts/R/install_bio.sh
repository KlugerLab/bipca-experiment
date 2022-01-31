#!/bin/bash
## expects r, install2.r, 
## installBioc.r and installGithub.r in the path.
set -e
NCPUS=${NCPUS:--1}

install2.r -n $NCPUS --skipinstalled anndata \
    remotes \
    Seurat \
    R.utils \
    BiocManager \
    purrr \
    gitcreds
installBioc.r DESeq2
installGithub.r satijalab/seurat-wrappers \
    mojaveazure/seurat-disk