# bipca-experiment: environment and experiments

This repository contains the necessary files to reproduce experiments from the bipca paper. We recommend that you use the docker image `bipca-experiment:latest`, however all of the necessary files for reproducing our experimental installation are contained within. 
## The docker image `bipca-experiment:latest`
The best way to reproduce the bipca environment is to launch a container from `bipca-experiment:latest`. Every experiment in the paper was created with this image.

### Environment variables for running the image
The environment variables for this image are important.  They are:

1) `USER`: The username that `jupyter-lab` will be run under, as well as the user for `r-session` and any commands run from the entrypoint. This defaults to `rstudio-bipca`
2) `USERID`: The Userid assigned to `$USER`. This defaults to `1000`.
3) `PASSWORD` The password assigned to `$USER`. Defaults to `bipca`
4) `ROOT`: gives `$USER` `sudo`. Defaults to `true`
5) `DISABLE_AUTH`: disables rstudio password authentication. Defaults to `true` - no login splash is displayed when connecting to rstudio.
6) `JUPYTER`: enable `jupyter-lab` on container start. Default `true`
7) `RSTUDIO`: enable `rstudio` on container start. Default `true`

### `bipca` installation
By default, this image installs `bipca` **at runtime** using `pip install -e /bipca`. What does this mean? Any directory that is a valid python module can be mounted at `/bipca` and installed. In particular, we use this for development of `bipca`: by mounting a host copy of the `bipca` github repo to `/bipca`, we can make changes to the source code that propagate into the container. Without any mounting, the `python` directory of a version of `bipca` (whichever version was last pulled into the submodule of this repo) was copied to `/bipca` when the image was built, so that version is installed. If a host-local `bipca/python` from the `bipca` github repository is mounted at the containers `/bipca` on runtime, the container `pip` will monitor host-side changes to `bipca` (such as pulling the latest commits from master, changing branches, or adding new code). 

### Breakdown of image runtime
Let's review what exactly this container does given the default settings.
1) Creates `$USER rstudio-bipca` with `$USERID 1000` and `$PASSWORD bipca`. If you're running unix, this means that any process launched within the container when logged in as default will run under the `USERID 1000`, which will show up in your host `ps` as whichever user on your host machine has `USERID 1000`.
2) Gives `sudo` to `$USER` within the container
3) Installs `bipca` from the path `/bipca` as an editable module using `pip`
4) Launches a `jupyter-lab` session on port `8080`. This is an extremely permissive notebook environment. There is no password or token associated with it, so any host port mapped to `8080` in the container you launch will have full access to the notebook.
5) Launches `rstudio-server` listening on port `8787`. Since `$DISABLE_AUTH` is `true` by default, when port `8787` of the docker container is requested, the requestor is automatically logged in to `$USER`.

### An example run command
The following command was used for all experiments in the paper:

`docker run -it --rm -p 8080:8080 -p 8029:8787 -e USER=$(id --name -u) -e USERID=$(id -g) --name bipca -v ~/bipca/python:/bipca -v /data:/data bipca-experiment:latest`

Its anatomy:
1) `docker run ... bipca-experiment:latest` run a container from the image `bipca-experiment:latest`
2) `-it` interactive session
3) `--rm` remove the container when it is stopped
4) `-p 8080:8080` forward container port `8080` to host port `8080`
5) `-p 8029:8787` forward container port `8787` to host port `8029`
6) `-e USER=$(id --name -u)` rename the default user to the user that is calling `docker run`. This changes the rstudio username, as well as any places **within the container** that the username is shown, such as the shell prompt or `ps`
7) `-e USERID=$(id -g)` change the id of $USER to the id of the current user on the host. This is especially important on systems which run docker native, e.g. linux, as processes run within the container (for example `jupyter-lab` or `r-session`) will export to the host's process manager (viewed by `htop` or `ps`) under this `$USERID`. By setting it to the current user, you ensure that your docker processes are mapped correctly to your username in the host.
8) `--name bipca` names the forthcoming container as `bipca`, which makes it easy to manipulate outside of the container
9) `-v ~/bipca/python:/bipca` mount the python directory of the host side bipca installation at `/home/$(id --name -u)/bipca/python`(or whatever your shell links to `~`) to the container-side volume `/bipca` (see above section "`bipca` installation".
11) `-v /data:/data` mount the host `/data` directory as a volume in the container at `/data`. As with any volume mounted in this way, changes made to the container `/data` will persist into the host `/data`. 


## Building the experimental environment from scratch
The following files can be used as a reference for rebuilding our environment inside of your own environment without using a dockerfile or docker image.

1) The experimental files to replicate experiments from the bipca paper. See `bipca-experiment/experiment`.
2) Scripts for normalization and preprocessing using comparison methods: `runNormalization.r`
2) Build scripts for the environment that all experiments were run in, barring basic installation of `conda/mamba, python, rstudio, and littler`. These scripts are contained in `bipca-experiment/build-scripts`

## Building the docker image
The following are used to build the docker image `bipca-experiment:latest`, but are not important for independently reproducing the experiments in your own environment. 

1) Jupyter notebook and ipython configuration files for mapping setting up jupyter lab as it was used in the paper, ccache and R makevars for speeding up R installations. These are less important for recreating the experiments, but they are contained in `bipca-experiment/root`
2) Configuration files for a jupyter service running in `s6`. These are unncessary for most, but the way that our docker image is setup, it uses `s6` to manage jupyter on container start. `/etc/services.d/jupyter`.
3) The dockerfile used to build `bipca-experiment:latest`, contained in `bipca-experiment/dockerfiles/bipca-base.dockerfile`
4) A build script that increments versions automatically and tags them, `bipca-exxperiment/build.sh`.

If you intend to build or modify the docker image ad hoc, we recommend that you either base your image on `bipca-experiment:latest`, or use `bipca-experiment/dockerfiles/bipca-base.dockerfile`. We recommend you roll your own build command, as `bipca-experiment/build.sh` is really only a convenience wrapper for internal development and publishing. To build `latest`, `cd` to the root of this repository and run:

`docker build -t <IMAGE NAME> --build-arg GITHUB_PAT=<GITHUB_PAT> --target=final -f dockerfiles/bipca-base.dockerfile  . `

`<IMAGE NAME>` for `latest` is `bipca-experiment:latest`. `<GITHUB_PAT>` is an argument that passes a github personal access token as an environment variable. This is used by the R package `remotes` to install repositories from `github`. It is not always necessary, but if you are working with a lot of other people on the same IP who are not using a PAT, your IP can be locked by github when a certain number of daily requests is reached.
