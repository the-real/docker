#!/bin/bash

## set ARG_HOME to a directory of your choosing if you do NOT
## want to to map the docker home directory to your local
## home directory

## use the command below on macOS or Linux to setup a 'launch'
## command. You can then use that command, e.g., launch ., to
## launch the container from any directory
## ln -s ~/git/docker/launch-rsm-jupyterhub.sh /usr/local/bin/launch

## to map the directory where the launch script is located to
## the docker home directory call the script_home function
script_home () {
  echo "$(echo "$( cd "$(dirname "$0")" ; pwd -P )" | sed -E "s|^/([A-z]{1})/|\1:/|")"
}

## catch arguments
while getopts ":t:d:" opt; do
  case $opt in
    t) ARG_TAG="$OPTARG"
    ;;
    d) ARG_DIR="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

## change to some other path to use as default
# ARG_HOME="~/rady"
# ARG_HOME="$(script_home)"
ARG_HOME=""
IMAGE_VERSION="latest"
ID="vnijs"
LABEL="rsm-jupyterhub"
IMAGE=${ID}/${LABEL}
NB_USER="jovyan"
if [ "$ARG_TAG" != "" ]; then
  IMAGE_VERSION="$ARG_TAG"
  DOCKERHUB_VERSION=${IMAGE_VERSION}
else
  ## see https://stackoverflow.com/questions/34051747/get-environment-variable-from-docker-container
  DOCKERHUB_VERSION=$(docker inspect -f '{{range $index, $value := .Config.Env}}{{println $value}} {{end}}' ${IMAGE}:${IMAGE_VERSION} | grep DOCKERHUB_VERSION)
  DOCKERHUB_VERSION="${DOCKERHUB_VERSION#*=}"
fi
POSTGRES_VERSION=10

## what os is being used
ostype=`uname`
if [ "$ostype" == "Darwin" ]; then
  EXT="command"
else
  EXT="sh"
fi
# if [ "$ostype" == "Linux" ] || [ "$ostype" == "Darwin" ]; then
#   ## check if script is already running
#   nr_running=$(ps | grep "${LABEL}.${EXT}" -c)
#   if [ "$nr_running" -gt 3 ]; then
#     clear
#     echo "-----------------------------------------------------------------------"
#     echo "The ${LABEL}.${EXT} launch script is already running (or open)"
#     echo "To close the new session and continue with the old session"
#     echo "press q + enter. To continue with the new session and stop"
#     echo "the old session press enter"
#     echo "-----------------------------------------------------------------------"
#     read contd
#     if [ "${contd}" == "q" ]; then
#       exit 1
#     fi
#   fi
# fi

## script to start Radiant, Rstudio, and JupyterLab
clear
has_docker=$(which docker)
if [ "${has_docker}" == "" ]; then
  echo "-----------------------------------------------------------------------"
  echo "Docker is not installed. Download and install Docker from"
  if [[ "$ostype" == "Linux" ]]; then
    echo "https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04"
  elif [[ "$ostype" == "Darwin" ]]; then
    echo "https://download.docker.com/mac/stable/Docker.dmg"
  else
    echo "https://store.docker.com/editions/community/docker-ce-desktop-windows"
  fi
  echo "-----------------------------------------------------------------------"
  read
else

  ## check docker is running at all
  ## based on https://stackoverflow.com/questions/22009364/is-there-a-try-catch-command-in-bash
  {
    docker ps -q
  } || {
    echo "-----------------------------------------------------------------------"
    echo "Docker is not running. Please start docker on your computer"
    echo "When docker has finished starting up press [ENTER] to continue"
    echo "-----------------------------------------------------------------------"
    read
  }

  ## kill running containers
  running=$(docker ps -q)
  if [ "${running}" != "" ]; then
    echo "-----------------------------------------------------------------------"
    echo "Stopping running containers"
    echo "-----------------------------------------------------------------------"
    docker stop ${running}
  fi

  available=$(docker images -q ${IMAGE}:${IMAGE_VERSION})
  if [ "${available}" == "" ]; then
    echo "-----------------------------------------------------------------------"
    echo "Downloading the ${LABEL}:${IMAGE_VERSION} computing container"
    echo "-----------------------------------------------------------------------"
    docker logout
    docker pull ${IMAGE}:${IMAGE_VERSION}
  fi

  ## function is not efficient by alias has scopping issues
  if [[ "$ostype" == "Linux" ]]; then
    HOMEDIR=~
    open_browser () {
      xdg-open $1
    }
    sed_fun () {
      sed -i $1 $2
    }
  elif [[ "$ostype" == "Darwin" ]]; then
    ostype="macOS"
    HOMEDIR=~
    open_browser () {
      open $1
    }
    sed_fun () {
      sed -i '' -e $1 $2
    }
  else
    ostype="Windows"
    HOMEDIR="C:/Users/$USERNAME"
    open_browser () {
      start $1
    }
    sed_fun () {
      sed -i $1 $2
    }
  fi

  ## change mapping of docker home directory to local directory if specified
  if [ "${ARG_HOME}" != "" ]; then
    if [ ! -d "${ARG_HOME}" ]; then
      echo "The directory ${ARG_HOME} does not yet exist."
      echo "Please create the directory and restart the launch script"
      sleep 5s
      exit 1
    fi
  fi

  if [ "$ARG_DIR" != "${ARG_HOME}" ]; then
    if [ "$ARG_DIR" != "" ]; then
      ARG_HOME="$(cd $ARG_DIR; pwd)"
      ## https://unix.stackexchange.com/questions/295991/sed-error-1-not-defined-in-the-re-under-os-x
      ARG_HOME="$(echo "$ARG_HOME" | sed -E "s|^/([A-z]{1})/|\1:/|")"

      echo "-------------------------------------------------------------------------"
      echo "Do you want to copy git, ssh, and R configuration to this directory (y/n)"
      echo "${ARG_HOME}"
      echo "-------------------------------------------------------------------------"
      read copy_config

      ## make sure no hidden files go into a git repo
      touch ${ARG_HOME}/.gitignore
      sed_fun '/^\.\*/d' ${ARG_HOME}/.gitignore
      echo ".*" >> ${ARG_HOME}/.gitignore

      if [ "${copy_config}" == "y" ]; then
        if [ -f "${HOMEDIR}/.inputrc" ] && [ ! -f "${ARG_HOME}/.inputrc" ]; then
          cp -p ${HOMEDIR}/.inputrc ${ARG_HOME}/.inputrc
        fi
        if [ -f "${HOMEDIR}/.Rprofile" ] && [ ! -f "${ARG_HOME}/.Rprofile" ]; then
          cp -p ${HOMEDIR}/.Rprofile ${ARG_HOME}/.Rprofile
        fi
        if [ -f "${HOMEDIR}/.Renviron" ] && [ ! -f "${ARG_HOME}/.Renviron" ]; then
          cp -p ${HOMEDIR}/.Renviron ${ARG_HOME}/.Renviron
        fi
        if [ -f "${HOMEDIR}/.gitconfig" ] && [ ! -f "${ARG_HOME}/.gitconfig" ]; then
          cp -p ${HOMEDIR}/.gitconfig ${ARG_HOME}/.gitconfig
        fi
        if [ -d "${HOMEDIR}/.ssh" ] && [ ! -d "${ARG_HOME}/.ssh" ]; then
          ## symlinks won't work because they would point to a non-existent directory
          cp -r -p ${HOMEDIR}/.ssh ${ARG_HOME}/.ssh
        fi
      fi
    fi

    if [ -d "${HOMEDIR}/.rstudio" ] && [ ! -d "${ARG_HOME}/.rstudio" ]; then
      echo "-----------------------------------------------------------------------"
      echo "Copying Rstudio and JupyterLab settings to:"
      echo "${ARG_HOME}"
      echo "-----------------------------------------------------------------------"

      {
        which rsync 2>/dev/null
        HD="$(echo "$HOMEDIR" | sed -E "s|^([A-z]):|/\1|")"
        AH="$(echo "$ARG_HOME" | sed -E "s|^([A-z]):|/\1|")"
        rsync -a ${HD}/.rstudio ${AH}/ --exclude sessions --exclude projects --exclude projects_settings
      } ||
      {
        cp -r ${HOMEDIR}/.rstudio ${ARG_HOME}/.rstudio
        rm -rf ${ARG_HOME}/.rstudio/sessions
        rm -rf ${ARG_HOME}/.rstudio/projects
        rm -rf ${ARG_HOME}/.rstudio/projects_settings
      }

    fi
    if [ -d "${HOMEDIR}/.rsm-msba" ] && [ ! -d "${ARG_HOME}/.rsm-msba" ]; then

      {
        which rsync 2>/dev/null
        HD="$(echo "$HOMEDIR" | sed -E "s|^([A-z]):|/\1|")"
        AH="$(echo "$ARG_HOME" | sed -E "s|^([A-z]):|/\1|")"
        rsync -a ${HD}/.rsm-msba ${AH}/ --exclude R --exclude bin --exclude lib --exclude share
      } ||
      {
        cp -r ${HOMEDIR}/.rsm-msba ${ARG_HOME}/.rsm-msba
        rm -rf ${ARG_HOME}/.rsm-msba/R
        rm -rf ${ARG_HOME}/.rsm-msba/bin
        rm -rf ${ARG_HOME}/.rsm-msba/lib
        rm_list=$(ls ${ARG_HOME}/.rsm-msba/share | grep -v jupyter)
        for i in ${rm_list}; do
           rm -rf ${ARG_HOME}/.rsm-msba/share/${i}
        done
      }
    fi
    SCRIPT_HOME="$(script_home)"
    if [ "${SCRIPT_HOME}" != "${ARG_HOME}" ]; then
      cp -p "$0" ${ARG_HOME}/launch-${LABEL}.${EXT}
      sed_fun "s+^ARG_HOME\=\".*\"+ARG_HOME\=\"\$\(script_home\)\"+" ${ARG_HOME}/launch-${LABEL}.${EXT}
      if [ "$ARG_TAG" != "" ]; then
        sed_fun "s/^IMAGE_VERSION=\".*\"/IMAGE_VERSION=\"${IMAGE_VERSION}\"/" ${ARG_HOME}/launch-${LABEL}.${EXT}
      fi
    fi
    HOMEDIR=${ARG_HOME}
  fi

  ## legacy - moving R/ directory with local installed packages
  if [ -d "${HOMEDIR}/R" ] && [ ! -d "${HOMEDIR}/.rsm-msba/R" ]; then
    echo "-----------------------------------------------------------------------"
    if [ "$ostype" != "Linux" ]; then
      echo "Moving user installed libraries to .rsm-msba/R"
      echo "To install additional libraries use:"
      echo "install.packages('a-package', lib = Sys.getenv('R_LIBS_USER'))"

      cp -r ${HOMEDIR}/R ${HOMEDIR}/.rsm-msba
      rm -rf ${HOMEDIR}/R
    fi
    echo "-----------------------------------------------------------------------"
  fi

  BUILD_DATE=$(docker inspect -f '{{.Created}}' ${IMAGE}:${IMAGE_VERSION})

  echo "-----------------------------------------------------------------------"
  echo "Starting the ${LABEL} computing container on ${ostype}"
  echo "Version   : ${DOCKERHUB_VERSION}"
  echo "Build date: ${BUILD_DATE//T*/}"
  echo "Base dir. : ${HOMEDIR}"
  echo "-----------------------------------------------------------------------"

  has_volume=$(docker volume ls | awk "/pg_data/" | awk '{print $2}')
  if [ "${has_volume}" == "" ]; then
    docker volume create --name=pg_data
  fi

  docker run --rm -p 127.0.0.1:8888:8888 -p 127.0.0.1:8765:8765 \
    -e NB_USER=0 -e NB_UID=1002 -e NB_GID=1002 \
    -v ${HOMEDIR}:/home/${NB_USER} \
    -v pg_data:/var/lib/postgresql/${POSTGRES_VERSION}/main \
    ${IMAGE}:${IMAGE_VERSION}

  ## make sure abend is set correctly
  ## https://community.rstudio.com/t/restarting-rstudio-server-in-docker-avoid-error-message/10349/2
  rstudio_abend () {
    if [ -d ${HOMEDIR}/.rstudio/sessions/active ]; then
      RSTUDIO_STATE_FILES=$(find ${HOMEDIR}/.rstudio/sessions/active/*/session-persistent-state -type f 2>/dev/null)
      if [ "${RSTUDIO_STATE_FILES}" != "" ]; then
        sed_fun 's/abend="1"/abend="0"/' ${RSTUDIO_STATE_FILES}
      fi
    fi
    if [ -d ${HOMEDIR}/.rstudio/monitored/user-settings ]; then
      touch ${HOMEDIR}/.rstudio/monitored/user-settings/user-settings
      sed_fun '/^alwaysSaveHistory="[0-1]"/d' ${HOMEDIR}/.rstudio/monitored/user-settings/user-settings
      sed_fun '/^loadRData="[0-1]"/d' ${HOMEDIR}/.rstudio/monitored/user-settings/user-settings
      sed_fun '/^saveAction=/d' ${HOMEDIR}/.rstudio/monitored/user-settings/user-settings
      echo 'alwaysSaveHistory="1"' >> ${HOMEDIR}/.rstudio/monitored/user-settings/user-settings
      echo 'loadRData="0"' >> ${HOMEDIR}/.rstudio/monitored/user-settings/user-settings
      echo 'saveAction="0"' >> ${HOMEDIR}/.rstudio/monitored/user-settings/user-settings
      sed_fun '/^$/d' ${HOMEDIR}/.rstudio/monitored/user-settings/user-settings
    fi
  }
  rstudio_abend
fi
