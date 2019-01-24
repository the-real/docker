git pull
docker login
DOCKERHUB_VERSION=1.3.1
UPLOAD="NO"
UPLOAD="YES"

build () {
  {
    if [[ "$1" == "NO" ]]; then
      docker build --build-arg DOCKERHUB_VERSION_UPDATE=${DOCKERHUB_VERSION} --no-cache -t $USER/${LABEL}:latest -f ./${LABEL}/Dockerfile-update .
    else
      docker build --build-arg DOCKERHUB_VERSION_UPDATE=${DOCKERHUB_VERSION} -t $USER/${LABEL}:latest -f ./${LABEL}/Dockerfile-update .
    fi
    docker tag $USER/${LABEL}:latest $USER/${LABEL}:${DOCKERHUB_VERSION}
  } || {
    echo "-----------------------------------------------------------------------"
    echo "Docker build for ${LABEL} was not successful"
    echo "-----------------------------------------------------------------------"
    sleep 3s
    exit 1
  }
  if [ "${UPLOAD}" == "YES" ]; then
    docker push $USER/${LABEL}:${DOCKERHUB_VERSION}; docker push $USER/${LABEL}:latest
  fi
}

# what os is being used
ostype=`uname`
if [[ "$ostype" == "Darwin" ]]; then
  sed_fun () {
    sed -i '' -e $1 $2
  }
else
  sed_fun () {
    sed -i $1 $2
  }
fi

launcher () {
  cp -p ./launch-$1.sh ./launch-${LABEL}.sh
  sed_fun "s/^LABEL=\"$1\"/LABEL=\"${LABEL}\"/" ./launch-${LABEL}.sh
  sed_fun "s/launch-$1\.sh/launch-${LABEL}\.sh/" ./launch-${LABEL}.sh
  if [ "$2" != "" ] && [ "$3" != "" ]; then
    sed_fun "s/$2/$3/" ./launch-${LABEL}.sh
  fi
}

LABEL=radiant
build NO

LABEL=rsm-msba
build NO

LABEL=rsm-msba-spark
build NO
launcher "rsm-msba"

# LABEL=rsm-jupyterhub
# build

# LABEL=rsm-msba-beakerx
# build
# launcher "rsm-msba"

# git add .
# git commit -m "Update to image version ${DOCKERHUB_VERSION}"
# git commit -m "Update to R and Python cleanup steps"
# git push
