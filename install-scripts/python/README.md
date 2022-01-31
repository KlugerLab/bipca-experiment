# bipca-experiment pythonR environment
These scripts are designed to install the python packages used for the experiments in the biPCA paper excluding the main bipca package, which is installed at runtime by the docker container.

They are installed by default in the `klugerlab/bipca-experiment` image or any docker image built from the dockerfile at `bipca-experiment/dockerfiles/bipca-base.dockerfile`. These images are built from `continuumio/miniconda3` with the `build-essentials` package from `apt-get` installed.

`install-python.sh` is essentially a wrapper around `conda` which installs `mamba` and then uses `mamba` to build the experimental environment `bipca-experiment` using the `environment.yml` file for conda requirements and `requirements.txt` for `pip` requirements.

You may use these scripts/environment files within your own docker image or adapt them to suit your own environment. These scripts assumes that `conda` is in the path. Since `bipca` is not installed by this script, you will additionally need to `pip install bipca` either by cloning the github repo and specifying its path, pointing to the submodule in `bipca-experiment`, or (if available) getting the package from `pip`.