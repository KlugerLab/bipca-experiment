# bipca-experiment R environment
These scripts are designed to install the R packages used for the experiments in the biPCA paper.
They are adapted from the [rocker/rocker-versioned2](https://github.com/rocker-org/rocker-versioned2) repository, and intended to work within a docker image based on `rocker/rstudio:4.1.1`. 


They are installed by default in the `klugerlab/bipca-experiment` image, or any docker image built from the dockerfile at `bipca-experiment/dockerfiles/bipca-base.dockerfile`.


You may use them within your own docker image or adapt them to suit your own environment. These scripts assume that `r-littler` is installed, and `r`, `install2.r`, `installBioc.r`, and `installGithub.r` are all in the path.


In order of execution, `install_tidyverse.sh` installs the tidyverse into an active R installation. Then `install_bio.sh` installs the relevant biological packages used by bipca-experiment, such as DESeq and Seurat. 