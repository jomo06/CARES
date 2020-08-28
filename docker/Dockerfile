# Build instructions for customized JupyterLab service image

# Note that this image assumes you have a conda-generated environment.yml
# file that defines the python dependencies you need in a new conda 
# environment and in that file's `pip` section it assumes you have a local
# package available in the working directory that it can install.

FROM jupyter/tensorflow-notebook:54462805efcb
MAINTAINER Dave Rench McCauley <drench56@gmail.com>

# must reset to user root to install more stuff
USER root

# Setup bash as default shell
SHELL ["/bin/bash", "--login", "-c"]

# apt-utils is missing and needed to avoid warning about skipping debconf
RUN apt-get update && apt-get --yes install apt-utils
RUN apt-get -y install curl


# Back to main jupyter user for python-specific stuff
USER jovyan

WORKDIR /home/jovyan/work/

# Copy everything from current working directory into WORKDIR in container
# Only really need setup.py, src/, and environment.yml
COPY environment.yml .
COPY setup.py .
COPY src .

# Install packages from original environment
RUN conda env create -f environment.yml


# Make sure base env has plotly
RUN conda install plotly=4.9.0 ipywidgets=7.5.1 nb_conda_kernels=2.2.3 nbdime=2.0.0 -y

# Install my favorite JupyterLab extensions
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager \
@jupyterlab/toc \
@ryantam626/jupyterlab_code_formatter@1.3.6

#TODO: get plotly ext to install w/o requiring new build on container launch
RUN jupyter labextension install jupyterlab-plotly --no-build
#RUN jupyter labextension install jupyterlab-plotly@4.9.0

# Finish off the code formatter extension install
RUN conda install -c conda-forge -y jupyterlab_code_formatter=1.3.6 -y
RUN jupyter serverextension enable --py jupyterlab_code_formatter
RUN conda install autopep8=1.5.3 -y


# Thanks to https://pythonspeed.com/articles/activate-conda-dockerfile/ for this code to make activation work
# Make RUN commands use the new environment and default to bash shell
ARG conda_env_name="$(head -1 environment.yml | cut -d' ' -f2)"
RUN conda init