FROM continuumio/miniconda3:4.10.3p1 AS python

WORKDIR /docker
RUN apt-get update -y && \
        apt-get install -y build-essential

COPY ./install-scripts/python /install-scripts/python

RUN /install-scripts/python/install_python.sh
ENV PATH /opt/conda/envs/bipca-experiment/bin:$PATH
COPY ./docker-shell-scripts/_activate_current_env.sh /usr/local/bin/_activate_current_env.sh
COPY ./docker-shell-scripts/_dockerfile_shell.sh /usr/local/bin/_dockerfile_shell.sh
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
RUN conda clean --all

FROM rocker/rstudio:4.1.1 as rstudio
#COPY ALL THE CONDA STUFF FROM THE PREVIOUS BUILD STAGE
#SET UP THE CONDA ENVIRONMENT
ENV CONDA_EXE=/opt/conda/bin/conda 
ENV CONDA_PREFIX=/opt/conda/envs/bipca-experiment 
ENV CONDA_PROMPT_MODIFIER=(bipca-experiment) 
ENV _CE_CONDA= 
ENV CONDA_SHLVL=1 
ENV SHLVL=0 
ENV CONDA_PYTHON_EXE=/opt/conda/bin/python 
ENV CONDA_DEFAULT_ENV=bipca-experiment
ENV PATH=/opt/conda/envs/bipca-experiment/bin:/opt/conda/condabin:/opt/conda/envs/bipca-experiment/bin:/opt/conda/bin:$PATH
COPY --from=python /usr/local/bin /usr/local/bin
RUN ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate bipca-experiment" >> ~/.bashrc
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
COPY --from=python /opt/conda /opt/conda

COPY --from=python /docker /docker
COPY ./root/.ccache /root/.ccache
COPY ./root/.R /root/.R
COPY --from=python /install-scripts /install-scripts
RUN chmod -R 777 /root
RUN chmod -R 777 /home/
RUN chmod -R 777 /docker


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
RUN touch /var/log/jupyter.log 
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
# Add a command to chown /opt/conda. This is required for some packages to work properly,
# and conda/mamba can now be used without sudo. (THIS IS COVERED IN THE ENTRYPOINT BY THE ENV VARIABLE)
#RUN printf '\n echo "chown -R $USER /opt/conda"\nchown -R $USER /opt/conda/' >> /etc/cont-init.d/userconf
# For some reason, the original userconf doesn't copy the home directory unless 
# the user id is 1000. So we need to edit the file by removing a few lines and changing others.
# we'll just clear the lines and then re-insert where necessary
# clear:
RUN sed -i '/.*useradd -m $USER -u $USERID.*/d ' /etc/cont-init.d/userconf && \
    sed -i '/.*mkdir -p \/home\/$USER.*/d '  /etc/cont-init.d/userconf && \
    sed -i '/.*echo "deleting the default user".*/d' /etc/cont-init.d/userconf && \
    sed -i '/.*userdel $DEFAULT_USER.*/d' /etc/cont-init.d/userconf

#now insert the lines we need
#First we change the username of the $DEFAULT USER to $USER
RUN sed -i '/.*chown -R $USER \/home\/$USER/i \ \ \ \ usermod -l $USER $DEFAULT_USER' /etc/cont-init.d/userconf && \
    sed -i '/.*chown -R $USER \/home\/$USER/i \ \ \ \ usermod -u $USERID $USER' /etc/cont-init.d/userconf && \
    sed -i '/.*chown -R $USER \/home\/$USER/i \ \ \ \ cp -r \/root\/ \/home\/$USER' /etc/cont-init.d/userconf && \
    sed -i '/.*chown -R $USER \/home\/$USER/i \ \ \ \ usermod -d \/home\/$USER $USER' /etc/cont-init.d/userconf && \
    sed -i '/.*chown -R $USER \/home\/$USER/i \ \ \ \ groupmod -g $GROUPID -n $USER $DEFAULT_USER' /etc/cont-init.d/userconf && \
    sed -i 's/.*chown -R $USER \/home\/$USER.*/chown -R $USER:$USER \/home\/$USER\//' /etc/cont-init.d/userconf && \
    sed -i '/.*chown -R $USER:$USER \/home\/$USER\//a \ \ \ \ chown -R $USER:$USER \/bipca' /etc/cont-init.d/userconf



#Install the bipca scripts


ARG BIPCA_VERRSION=
# first copy to /bipca. this will be the default package that is pip installed at runtime.
COPY ./bipca/python /bipca
COPY ./etc/cont-init.d/z_install_bipca /etc/cont-init.d/z_install_bipca
RUN touch /var/log/pip.log
# the script for normalization methods
COPY runNormalization.r /bipca-experiments/runNormalization.r
RUN ln -s /bipca-experiments/runNormalization.r /opt/conda/bin/runNormalization.r

ENTRYPOINT ["service_entrypoint.sh"]
