FROM continuumio/miniconda3:4.10.3p1 AS python

WORKDIR /docker
#install scripts
COPY . /
ENV PATH /opt/conda/envs/bipca-experiment/bin:$PATH
#get the build essentials (compilers etc)
RUN apt-get update -y && \
    apt-get install -y build-essential && \
    #install the major python dependencies && clean
    /install-scripts/python/install_python.sh && \
    conda clean --all

FROM rocker/rstudio:4.1.1 as rstudio
#COPY ALL THE CONDA STUFF FROM THE PREVIOUS BUILD STAGE
#SET UP THE CONDA ENVIRONMENT
ARG GITHUB_PAT=''
ENV CONDA_EXE=/opt/conda/bin/conda \
    CONDA_PREFIX=/opt/conda/envs/bipca-experiment \
    CONDA_PROMPT_MODIFIER=(bipca-experiment) \
    _CE_CONDA= \
    CONDA_SHLVL=1 \
    SHLVL=0 \
    CONDA_PYTHON_EXE=/opt/conda/bin/python \
    CONDA_DEFAULT_ENV=bipca-experiment \
    NCPUS=32 \
    GITHUB_PAT=$GITHUB_PAT \
    PATH=/docker-shell-scripts/:/home/\$USER/.local/bin:/root/.local/bin:/opt/conda/envs/bipca-experiment/bin:/opt/conda/condabin:/opt/conda/envs/bipca-experiment/bin:/opt/conda/bin:$PATH
#grab all the docker shell scripts
#grab all the docker shell scripts, wd, root config, install-scripts, conda
COPY . /
COPY --from=python /opt/conda /opt/conda
#do some symlinking and activation stuff (maybe not necessary?)
SHELL ["_dockerfile_shell.sh"]
# Default command for "docker run"
CMD ["/bin/bash"]
RUN ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate bipca-experiment" >> ~/.bashrc && \
    #fix some permissions.. this may take awhile. we're using 777 here because I'm not sure what we really need :)
    chmod -R 777 /root && \
    chmod -R 777 /home/ && \
    chmod -R 777 /docker && \
    chmod -R 777 /install-scripts && \
    chmod -R 777 /opt && \
    #install R stuff
    #link bioconductor install script
    ln -s /usr/local/lib/R/site-library/littler/examples/installBioc.r /usr/local/bin/installBioc.r && \
     #install the relevant apt dependencies
     /install-scripts/R/install_deps.sh && \
     #install tidyverse
     /install-scripts/R/install_tidyverse.sh && \
     #install biology stuff
     /install-scripts/R/install_bio.sh && \
     # install sanity
     /install-scripts/Sanity/install_Sanity.sh && \
        # make sure github_pat is not in the environment anymore
     unset GITHUB_PAT && \
     echo 'export PATH="$PATH"' >> /root/.bashrc && \
    # copy all the configuration and . files from root into $DEFAULT_USER,
    # as that is what we have been editing and it appears that s6 maps $DEFAULT_USER
    # to $USER.. we also need to fix permissions
    cp -a /root/. /home/$DEFAULT_USER/ && \
    chown -R $DEFAULT_USER:$DEFAULT_USER /home/$DEFAULT_USER && \
    chown -R $DEFAULT_USER:staff /opt && \
    chmod -R 777 /opt/conda && \
    #log files? \
    touch /var/log/jupyter.log && \ 
    touch /var/log/pip.log && \
    # make some modifications to the default paths so that sudo has the same basic path
    sed -i "11s|.*|Defaults	secure_path = $(echo $PATH)|" /etc/sudoers && \
    # make /etc/environment have the conda path in it so that processes that read from
    # /etc/environment have the correct paths.\
    sed -i "s|.*PATH=.*|PATH=$(echo $PATH)|" /etc/environment && \
    # modify the userconf startup script...
    # For some reason, the original userconf doesn't copy the home directory unless 
    # the user id is 1000. So we need to edit the file by removing a few lines and changing others.
    # we'll just clear the lines first... 
    sed -i '/.*useradd -m $USER -u $USERID.*/d ' /etc/cont-init.d/userconf && \
    sed -i '/.*mkdir -p \/home\/$USER.*/d '  /etc/cont-init.d/userconf && \
    sed -i '/.*echo "deleting the default user".*/d' /etc/cont-init.d/userconf && \
    sed -i '/.*userdel $DEFAULT_USER.*/d' /etc/cont-init.d/userconf && \
    #ok everything is cleared... change the login username
    sed -i '/.*chown -R $USER \/home\/$USER/i \ \ \ \ usermod -l $USER $DEFAULT_USER' /etc/cont-init.d/userconf && \
    #change the uid
    sed -i '/.*chown -R $USER \/home\/$USER/i \ \ \ \ usermod -u $USERID $USER' /etc/cont-init.d/userconf && \
    #copy root to /home/user
    sed -i '/.*chown -R $USER \/home\/$USER/i \ \ \ \ cp -r \/root\/ \/home\/$USER' /etc/cont-init.d/userconf && \
    #set the home directory of the user
    sed -i '/.*chown -R $USER \/home\/$USER/i \ \ \ \ usermod -d \/home\/$USER $USER' /etc/cont-init.d/userconf && \
    #change the primary groupid and name (this defaults to $USERID in the entrypoint)
    sed -i '/.*chown -R $USER \/home\/$USER/i \ \ \ \ groupmod -g $GROUPID -n $USER $DEFAULT_USER' /etc/cont-init.d/userconf && \
    #change the ~ chown command to own the $USER:$USER format
    sed -i 's/.*chown -R $USER \/home\/$USER.*/chown -R $USER:$USER \/home\/$USER\//' /etc/cont-init.d/userconf && \
    #make the user own /bipca on boot
    sed -i '/.*chown -R $USER:$USER \/home\/$USER\//a \ \ \ \ chown -R $USER:$USER \/bipca' /etc/cont-init.d/userconf

# Setup the environment defaults for docker run and s6-init - not sure if these are all necessary
FROM rstudio as final
ENV GITHUB_PAT='' \
    DISABLE_AUTH=true \
    USER=rstudio-bipca \
    PASSWORD=bipca \
    USERID=1000 \
    ROOT=true \
    JUPYTER=true \
    RSTUDIO=true 
#Copy /install the bipca scripts
#the following line is to decache things
ARG BIPCA_VERRSION=
# first copy to /bipca. this will be the default package that is pip installed at runtime.
#this may look like a redundant copy step (as we have already run COPY . /, so /bipca/python exists..)
#however, pip looks to install from /bipca, not /bipca/python.
#furthermore, this allows us to bump the bipca version without clearing upstream cache.
COPY ./bipca/python /bipca
# the script for normalization methods
RUN ln -s /bipca-experiments/runNormalization.r /opt/conda/bin/runNormalization.r

ENTRYPOINT ["service_entrypoint.sh"]
