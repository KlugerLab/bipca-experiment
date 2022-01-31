# bipca-experiment installation scripts environment
These scripts are designed to install the packages used for the experiments in the biPCA paper. They are divided into three subfolders corresponding to stages of the build and distinct functions, 1) python, 2) R, and 3) Sanity. 

They are installed by default in the `klugerlab/bipca-experiment` image, or any docker image built from the dockerfile at `bipca-experiment/dockerfiles/bipca-base.dockerfile`. This directory is mounted by docker at `/install-scripts`

You may use them within your own docker image or adapt them to suit your own environment. See the individual `README.md` for each stage for build tips if you intend to use them outside of the `bipca-experiment` image, as well as consult the relevant regions of `bipca-experiment/dockerfiles/bipca-base.dockerfile`.