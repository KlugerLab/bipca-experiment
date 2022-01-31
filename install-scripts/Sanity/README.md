# bipca-experiment Sanity installation
`install_Sanity.sh` installs Sanity and its build requirement `libgomp` (using `apt-get`) into `/Sanity` and links the `Sanity` binary into `/usr/local/bin/Sanity`. 


This script is intended to be used within the `bipca-experiment` docker image, where it is built using the `rocker/rstudio:4.1.1` base image following installation of the `bipca-experiment` R environment by `bipca-experiment/install-scripts/R/install_R_env.sh`


Refer to the [Sanity github](https://github.com/jmbreda/Sanity) for more details.