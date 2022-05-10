
FROM continuumio/miniconda3:4.10.3p1 AS python

WORKDIR /docker
RUN apt-get update -y && \
        apt-get install -y build-essential && \
        apt-get install -y texlive

COPY ./install-scripts/python /install-scripts/python

RUN /install-scripts/python/install_python.sh
ENV PATH /opt/conda/envs/bipca-experiment/bin:$PATH
COPY ./docker-shell-scripts/_activate_current_env.sh /usr/local/bin/_activate_current_env.sh
COPY ./docker-shell-scripts/_dockerfile_shell.sh /usr/local/bin/_dockerfile_shell.sh
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]


FROM rocker/rstudio:4.1.1 as rstudio
#COPY ALL THE CONDA STUFF FROM THE PREVIOUS BUILD STAGE
COPY --from=python /opt/conda /opt/conda
COPY --from=python /docker /docker
COPY ./root/.ccache /root/.ccache
COPY ./root/.R /root/.R
COPY --from=python /usr/local/bin /usr/local/bin
COPY --from=python /install-scripts /install-scripts
RUN chmod -R 777 /root
RUN chmod -R 777 /home/
RUN chmod -R 777 /docker
#SET UP THE CONDA ENVIRONMENT
ENV PATH /opt/conda/bin:/opt/conda/condabin:/opt/conda/bin:$PATH
ENV CONDA_PREFIX=/opt/conda
ENV CONDA_EXE=/opt/conda/bin/conda
ENV CONDA_DEFAULT_ENV=bipca-experiment
ENV CONDA_PYTHON_EXE=/opt/conda/bin/python
RUN ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate bipca-experiment" >> ~/.bashrc
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
# Default command for "docker run"
CMD ["/bin/bash"]

#INSTALL R-related stuff

ENV NCPUS=32
#link biocmanager, which is required for install_bio.sh
#github and install2.r have already been linked by rocker.
RUN ln -s /usr/local/lib/R/site-library/littler/examples/installBioc.r /usr/local/bin/installBioc.r

COPY ./install-scripts/R/install_deps.sh /install-scripts/R/install_deps.sh
RUN ./install-scripts/R/install_deps.sh 
COPY ./install-scripts/R/install_tidyverse.sh /install-scripts/R/install_tidyverse.sh
RUN /install-scripts/R/install_tidyverse.sh
ARG GITHUB_PAT=''
ENV GITHUB_PAT=$GITHUB_PAT
COPY ./install-scripts/R/install_bio.sh /install-scripts/R/install_bio.sh
RUN /install-scripts/R/install_bio.sh
RUN unset GITHUB_PAT
FROM rstudio as sanity
#Install Sanity
COPY ./install-scripts/Sanity /install-scripts/Sanity
RUN /install-scripts/Sanity/install_Sanity.sh

# Setup the environment defaults for docker run and s6-init
FROM sanity as final
ENV DISABLE_AUTH=true 
ENV USER=rstudio-bipca 
ENV PASSWORD=bipca
ENV USERID=1000
ENV ROOT=true
ENV JUPYTER=true
ENV RSTUDIO=true
#s6 services config
COPY ./etc/services.d/jupyter /etc/services.d/jupyter
#jupyter config
COPY ./root/.jupyter /root/.jupyter
#ipython config
COPY ./root/.ipython /root/.ipython
#entrypoint script
COPY ./docker-shell-scripts/service_entrypoint.sh /usr/local/bin/service_entrypoint.sh
#conda config script
COPY /root/.condarc /root/.condarc

# modify the path to make pip happy
RUN echo 'export PATH=/home/$USER/.local/bin:/root/.local/bin:'$PATH'' >> /root/.bashrc 
# copy all the configuration and . files from root into $DEFAULT_USER,
# as that is what we have been editing and it appears that s6 maps $DEFAULT_USER
# to $USER
RUN chmod -R 777 /root && \
    cp -a /root/. /home/$DEFAULT_USER/ && \
    chown -R $DEFAULT_USER:staff /opt && \
    chmod -R 777 /opt/conda
ENV PATH /home/\$USER/.local/bin:/root/.local/bin:$PATH

# make some modifications to the default paths so that sudo has the same basic path
RUN sed -i "11s|.*|Defaults	secure_path = $(echo $PATH)|" /etc/sudoers
# make /etc/environment have the conda path in it so that processes that read from
# /etc/environment have the correct paths.
RUN sed -i "s|.*PATH=.*|PATH=$(echo $PATH)|" /etc/environment
# modify the userconf startup script...

COPY ./etc/cont-init.d /etc/cont-init.d

#Install the bipca scripts


# first copy to /bipca. this will be the default package that is pip installed at runtime.
COPY ./bipca/python /bipca
# the script for normalization methods
COPY ./bipca-experiment/runNormalization.r /bipca-experiment/runNormalization.r
RUN ln -s /bipca-experiment/runNormalization.r /opt/conda/bin/runNormalization.r

ENTRYPOINT ["service_entrypoint.sh"]
