FROM vnijs/rsm-msba:latest

MAINTAINER Vincent Nijs "radiant@rady.ucsd.edu"

ARG DOCKERHUB_VERSION_UPDATE
ENV DOCKERHUB_VERSION=${DOCKERHUB_VERSION_UPDATE}

## install the bash kernel
COPY requirements.txt /home/${NB_USER}/requirements.txt

## from https://github.com/takluyver/bash_kernel
RUN pip3 install -r /home/${NB_USER}/requirements.txt \
  && rm /home/${NB_USER}/requirements.txt \
  && python3 -m bash_kernel.install

## extension not supported in jupyterlab >= 0.35
# && jupyter labextension install @jupyterlab/shortcutui \
# Clone the repo to your local environment
#RUN git clone https://github.com/jupyterlab/jupyterlab-shortcutui.git \
#  && cd jupyterlab-shortcutui \
#  && npm install \
#  && npm run build \
#  && jupyter labextension link . \
#  && cd ../ \
#  && rm -rf jupyterlab-shortcutui

## install the variable inspector
# RUN git clone https://github.com/lckr/jupyterlab-variableInspector \
#  && cd jupyterlab-variableInspector \
#  && npm install \
#  && npm run build  \
#  && jupyter labextension install . \
#  && cd ../ \
#  && rm -rf jupyterlab-variableInspector

## install the typescript kernel
# RUN npm --unsafe-perm install -g itypescript \
#  && its --ts-install=global

## install the javascript kernel
# RUN npm --unsafe-perm install -g ijavascript \
#  && ijsinstall --install=global

## update R-packages
RUN R -e 'radiant.update::radiant.update()'

## update radiant to development version
# RUN R -e 'remotes::install_github("radiant-rstats/radiant.data", upgrade = "never")' \
#  -e 'remotes::install_github("radiant-rstats/radiant.basics", upgrade = "never")' \
#  -e 'remotes::install_github("radiant-rstats/radiant.design", upgrade = "never")' \
#  -e 'remotes::install_github("radiant-rstats/radiant.model", upgrade = "never")' \
#  -e 'remotes::install_github("radiant-rstats/radiant.multivariate", upgrade = "never")'

#ARG CODESRV=1.32.0-310
#RUN wget https://github.com/codercom/code-server/releases/download/${CODESRV}/code-server-${CODESRV}-linux-x64.tar.gz \
#  && tar -xzf code-server-${CODESRV}-linux-x64.tar.gz \
#  && mv code-server-${CODESRV}-linux-x64/code-server /usr/local/bin \
#  && rm -rf code-server-${CODESRV}-linux-x64*

# COPY jupyter_notebook_config.py /etc/jupyter/
# EXPOSE 8080 8787 8989 8765 8443

# RUN jupyter labextension install @jupyterlab/monaco
# RUN git clone https://github.com/jupyterlab/jupyterlab-monaco.git \
#  && cd jupyterlab-monaco/ \
#  && npm install \
#  && npm run build \
#  && jupyter labextension link .

ENV CODE_USER_DATA_DIR="~/.rsm-msba/share/code-server"
ENV CODE_EXTENSIONS_DIR="~/.rsm-msba/share/code-server/extensions"

RUN cd /opt \
  && mkdir /opt/code-server \
  && cd /opt/code-server \
  && wget -qO- https://github.com/codercom/code-server/releases/download/1.604-vsc1.32.0/code-server1.604-vsc1.32.0-linux-x64.tar.gz | tar zxvf - --strip-components=1

ENV PATH=/opt/code-server:$PATH

#RUN echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
# RUN echo "fs.inotify.max_user_watches=8192" >> /etc/sysctl.conf \
# RUN sysctl -w fs.inotify.max_user_watches=12288
# && sysctl -p

RUN pip3 install git+https://github.com/vnijs/jupyter_codeserver_proxy.git pylint

## gives error sysctl: setting key "fs.inotify.max_user_watches": Read-only file system
RUN echo "fs.inotify.max_user_watches=8192" >> /etc/sysctl.conf \
  && sysctl -p

EXPOSE 8080 8787 8989 8765

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
