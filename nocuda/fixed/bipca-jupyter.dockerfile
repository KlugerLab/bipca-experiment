
FROM jay:bipca-nocuda-base-fixed

ARG MAMBA_DOCKERFILE_ACTIVATE=1
RUN micromamba install -y jupyterlab jupyter -c conda-forge
RUN jupyter-lab --generate-config
RUN ipython profile create
RUN printf "\nc.ServerApp.ip = '0.0.0.0'\n" >> /home/$UNAME/.jupyter/jupyter_lab_config.py
RUN printf "\nc.ServerApp.token = ''\n" >> /home/$UNAME/.jupyter/jupyter_lab_config.py
RUN printf "\nc.ServerApp.password = ''\n" >> /home/$UNAME/.jupyter/jupyter_lab_config.py
RUN printf "\nc.ServerApp.port = 8080\n" >> /home/$UNAME/.jupyter/jupyter_lab_config.py
RUN printf "\nc.NotebookApp.notebook_dir = '/home'\n" >> /home/$UNAME/.jupyter/jupyter_lab_config.py
RUN printf "\nc.NotebookApp.terminado_settings={'shell_command':['bash', '--login']}" >>/home/$UNAME/.jupyter/jupyter_lab_config.py

RUN printf "\nc = get_config()" >> /home/$UNAME/.ipython/profile_default/ipython_config.py
RUN printf "\nc.InlineBackend.print_figure_kwargs={'facecolor' : 'w'}">> /home/$UNAME/.ipython/profile_default/ipython_config.py
RUN printf "\nc = get_config()" >> /home/$UNAME/.ipython/profile_default/ipython_kernel_config.py
RUN printf "\nc.InlineBackend.print_figure_kwargs={'facecolor' : 'w'}">> /home/$UNAME/.ipython/profile_default/ipython_kernel_config.py
ENTRYPOINT ["jupyter-lab","&","/bin/bash"]