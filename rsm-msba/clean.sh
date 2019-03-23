#!/bin/bash

## script to run from jupyter lab to clean up settings
## and remove locally install R and python packages
## cleaning up settings is a common requirement for Rstudio

echo "-----------------------------------------------------"
echo "Clean up Rstudio sessions and settings (y/n)?"
echo "-----------------------------------------------------"
read cleanup

if [ "${cleanup}" == "y" ]; then
  echo "Cleaning up Rstudio sessions and settings"
  sudo rm -rf ~/.rstudio/sessions
  sudo rm -rf ~/.rstudio/projects
  sudo rm -rf ~/.rstudio/projects_settings

  ## make sure abend is set correctly
  ## https://community.rstudio.com/t/restarting-rstudio-server-in-docker-avoid-error-message/10349/2
  rstudio_abend () {
    if [ -d ~/.rstudio/monitored/user-settings ]; then
      touch ~/.rstudio/monitored/user-settings/user-settings
      sed -i '/^alwaysSaveHistory="[0-1]"/d' ~/.rstudio/monitored/user-settings/user-settings
      sed -i '/^loadRData="[0-1]"/d' ~/.rstudio/monitored/user-settings/user-settings
      sed -i '/^saveAction=/d' ~/.rstudio/monitored/user-settings/user-settings
      echo 'alwaysSaveHistory="1"' >> ~/.rstudio/monitored/user-settings/user-settings
      echo 'loadRData="0"' >> ~/.rstudio/monitored/user-settings/user-settings
      echo 'saveAction="0"' >> ~/.rstudio/monitored/user-settings/user-settings
      sed -i '/^$/d' ~/.rstudio/monitored/user-settings/user-settings
    fi
  }
  rstudio_abend
fi

echo "-----------------------------------------------------"
echo "Remove locally installed R packages (y/n)?"
echo "-----------------------------------------------------"
read cleanup

if [ "${cleanup}" == "y" ]; then
  echo "Removing locally installed R packages"
  rm -rf ~/.rsm-msba/R
fi

echo "-----------------------------------------------------"
echo "Remove locally installed Python packages (y/n)?"
echo "-----------------------------------------------------"
read cleanup

if [ "${cleanup}" == "y" ]; then
  echo "Removing locally installed Python packages"
  rm -rf ~/.rsm-msba/bin
  rm -rf ~/.rsm-msba/lib
  cd ~/.rsm-msba/share
  ls | grep -v jupyter | xargs rm -rf 2>/dev/null
  cd -
fi

echo "-----------------------------------------------------"
echo "Cleanup complete"
echo "-----------------------------------------------------"
