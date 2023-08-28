FROM rocker/rstudio:4.1.1 as rstudio

WORKDIR /docker
RUN apt-get update -y && \
    apt-get install -y build-essential && \ 
    apt-get install -y texlive dvipng texlive-latex-extra \
    texlive-fonts-recommended cm-super

ENV DISABLE_AUTH=true 
ENV USER=rstudio-bipca 
ENV PASSWORD=bipca
ENV USERID=1000
ENV ROOT=true
ENV JUPYTER=true
ENV RSTUDIO=true

#INSTALL R-related stuff
ENV NCPUS=32
#link biocmanager, which is required for install_bio.sh
#github and install2.r have already been linked by rocker.
RUN ln -s /usr/local/lib/R/site-library/littler/examples/installBioc.r /usr/local/bin/installBioc.r

FROM rstudio as rstudio1
COPY ./install-scripts/R/ ./install-scripts/R
ARG GITHUB_PAT=''
ENV GITHUB_PAT=$GITHUB_PAT

RUN install-scripts/R/install_deps.sh  && \
  install-scripts/R/install_tidyverse.sh && \
  install-scripts/R/install_bio.sh

RUN unset GITHUB_PAT
FROM rstudio1 as sanity
#Install Sanity
COPY ./install-scripts/Sanity/ ./install-scripts/Sanity

RUN install-scripts/Sanity/install_Sanity.sh

FROM sanity as python
# Install Python
#GET CONDA
COPY --from=continuumio/miniconda3:latest /opt /opt
#SETUP CONDA ENVIRONMENT
ENV PATH /opt/conda/bin:/opt/conda/condabin:/opt/conda/bin:$PATH
ENV CONDA_PREFIX=/opt/conda
ENV CONDA_EXE=/opt/conda/bin/conda
ENV CONDA_PYTHON_EXE=/opt/conda/bin/python
RUN ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc

COPY ./install-scripts/python/ install-scripts/python
ARG CUDA_VERSION=''
RUN install-scripts/python/install_python.sh && \
    install-scripts/python/install_torch.sh $CUDA_VERSION
ENV PATH /opt/conda/envs/bipca-experiment/bin:$PATH
ENV CONDA_DEFAULT_ENV=bipca-experiment
COPY ./docker-shell-scripts /usr/local/bin/
COPY ./etc /etc/
COPY ./root /root

RUN echo "conda activate bipca-experiment" >> ~/.bashrc
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
CMD ["/bin/bash"]
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
FROM python as final
# first copy to /bipca. this will be the default package that is pip installed at runtime.
COPY ./bipca-experiment /bipca-experiment/

COPY ./bipca/ /bipca
#hack to make setuptools-scm work with submodules
RUN rm /bipca/.git
COPY ./.git/modules/bipca /bipca/.git/

# the script for normalization methods
RUN ln -s /bipca-experiment/runNormalization.r /opt/conda/bin/runNormalization.r && \
     ln -s /bipca-experiment/runNormalization.py /opt/conda/bin/runNormalization.py
ENTRYPOINT ["/usr/local/bin/service_entrypoint.sh"]
