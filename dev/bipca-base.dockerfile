FROM bipca:experiment-base

ARG MAMBA_DOCKERFILE_ACTIVATE=1

RUN pip uninstall -y bipca
VOLUME /bipca

ENTRYPOINT ["pip","install","-e","/bipca","&"]
