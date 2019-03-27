FROM vnijs/rsm-msba:latest

MAINTAINER Your Name "your-email@gmail.com"

## keeping track of the contianer version
ARG DOCKERHUB_VERSION_UPDATE
ENV DOCKERHUB_VERSION=${DOCKERHUB_VERSION_UPDATE}

## add python packages listed in the 'requirments.txt' file
COPY requirements.txt /home/${NB_USER}/requirements.txt
RUN pip3 install -r /home/${NB_USER}/requirements.txt \
  && rm /home/${NB_USER}/requirements.txt

## install an R-package
RUN R -e 'install.packages("bookdown")'

## install an R-package from GitHub
RUN R -e 'remotes::install_github("radiant-rstats/radiant.data", upgrade = "never")'

## indicate which ports will be used
EXPOSE 8080 8787 8989 8765

## start the 'services', Rstudio, JupyterLab, etc.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
