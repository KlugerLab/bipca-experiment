# Use nvidia/cuda image
FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04

ARG UNAME
ARG UID
ARG GID
ARG BIPCA=./bipca/python
ARG ENV=cuda/base-environment.yml
COPY --chown=$UID:$GID $BIPCA /bipca
WORKDIR /home/$UNAME/container
COPY --chown=$UID:$GID $ENV ./environment.yml

# set bash as current shell
SHELL ["/bin/bash", "-c"]
RUN whoami

RUN apt-get update && \
	apt-get -y install sudo
# I think the following code sets the user
RUN echo "UNAME: $UNAME, UID: $UID, GID: $GID"
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
RUN usermod -aG sudo $UNAME
RUN sudo chown -R $UNAME:$UNAME /home/$UNAME/
RUN sudo passwd -d $UNAME
RUN whoami
USER $UNAME
RUN whoami

VOLUME /code
# install anaconda
RUN sudo apt-get update -y && \
        sudo apt-get install -y wget bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial subversion && \
        sudo apt-get clean

RUN wget -O \
        mambaforge.sh \
        https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh \
        && bash mambaforge.sh -b \
        && source /home/${UNAME}/mambaforge/bin/activate
ENV PATH="/home/$UNAME/mambaforge/bin:$PATH"
ARG PATH="/home/$UNAME/mambaforge/bin:$PATH"
RUN mamba env update -n base -f ./environment.yml
RUN mamba init

RUN echo "conda activate base" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]
RUN mamba run -n base pip install /bipca 
#COPY entrypoint.sh ./
#RUN chown -R $UNAME:$UNAME entrypoint.sh
#RUN chmod +x entrypoint.sh
#ENTRYPOINT ["./entrypoint.sh"]


