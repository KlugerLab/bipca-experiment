# Use nvidia/cuda image
FROM bipca:experiment-jupyter

ARG MAMBA_DOCKERFILE_ACTIVATE=1

RUN pip uninstall -y bipca
VOLUME /bipca

ENTRYPOINT ["pip","install","-e","/bipca","&", "jupyter-lab","&","/bin/bash"]
