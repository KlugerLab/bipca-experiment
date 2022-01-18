
FROM mambaorg/micromamba as mm

ARG BIPCA=./bipca/python
ARG ENVIRONMENT=nocuda/base-environment.yml

WORKDIR /docker

COPY --chown=$MAMBA_USER:$MAMBA_USER $BIPCA /bipca
COPY --chown=$MAMBA_USER:$MAMBA_USER $ENVIRONMENT ./environment.yml
COPY --chown=$MAMBA_USER:$MAMBA_USER runNormalization.r /bipca/runNormalization.r
RUN micromamba install -y -f environment.yml && \ 
        micromamba clean --all --yes
ARG MAMBA_DOCKERFILE_ACTIVATE=1
RUN pip install /bipca 

USER root
RUN apt-get update
RUN apt-get install -y r-base r-base-dev
RUN Rscript -e 'install.packages("littler")'
RUN ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r
RUN r -e "install.packages('docopt')"
RUN ln -s /usr/local/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r
RUN ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r

RUN apt-get install libssl-dev
RUN install.r Seurat, DESeq2, anndata
RUN install.r remotes
RUN installGithub.r satijalab/seurat-wrappers
RUN installGithub.r mojaveazure/seurat-disk


RUN apt-get update
RUN apt-get install libgomp1
RUN git clone https://github.com/jmbreda/Sanity.git /Sanity
WORKDIR /Sanity/src
RUN make
RUN ln -s Sanity/bin/Sanity /usr/local/bin/Sanity
WORKDIR /docker

RUN install.r purrr
RUN ln -s /bipca/runNormalization.r /usr/local/bin/runNormalization.r
