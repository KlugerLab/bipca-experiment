# bipca-experiment: environment and experiments

This repository contains the necessary files to reproduce experiments from the bipca paper. We recommend that you use the docker image `bipca-experiment:latest`, however all of the necessary files for reproducing our experimental installation are contained within. They are:

1) The experimental files to replicate experiments from the bipca paper. See `bipca-experiment/experiment`.
2) Scripts for normalization and preprocessing using comparison methods: `runNormalization.r`
2) Build scripts for the environment that all experiments were run in, barring basic installation of `conda/mamba, python, rstudio, and littler`. These scripts are contained in `bipca-experiment/build-scripts`


The following are used to build the docker image `bipca-experiment:latest`, but are not important for indepdently reproducing the experiments in your own environment. 
3) Jupyter notebook and ipython configuration files for mapping setting up jupyter lab as it was used in the paper, ccache and R makevars for speeding up R installations. These are less important for recreating the experiments, but they are contained in `bipca-experiment/root`
4) Configuration files for a jupyter service running in `s6`. These are unncessary for most, but the way that our docker image is setup, it uses `s6` to manage jupyter on container start. `/etc/services.d/jupyter`.
5) The dockerfile used to build `bipca-experiment:latest`, contained in `bipca-experiment/dockerfiles/bipca-base.dockerfile`
6) A build script that increments versions automatically and tags them, `bipca-exxperiment/build.sh`.

If you intend to build or modify the docker image ad hoc, we recommend that you either base your image on `bipca-experiment:latest`, or use `bipca-experiment/dockerfiles/bipca-base.dockerfile`. We recommend you roll your own build command, as `bipca-experiment/build.sh` is really only a convenience wrapper for internal development and publishing. To build `latest`, `cd` to the root of this repository and run:

`docker build -t <IMAGE NAME> --build-arg GITHUB_PAT=<GITHUB_PAT> --target=final -f dockerfiles/bipca-base.dockerfile  . `

`<IMAGE NAME>` for `latest` is `bipca-experiment:latest`. `<GITHUB_PAT>` is an argument that passes a github personal access token as an environment variable. This is used by the R package `remotes` to install repositories from `github`. It is not always necessary, but if you are working with a lot of other people on the same IP who are not using a PAT, your IP can be locked by github when a certain number of daily requests is reached.