# Contents
  - [Installing the RSM-MSBA computing environment on Linux](#installing-the-rsm-msba-computing-environment-on-linux) 
  - [Updating the RSM-MSBA computing environment on Linux](#updating-the-rsm-msba-computing-environment-on-linux) 
  - [Connecting to postgresql](#connecting-to-postgresql)
  - [Extended functionality with Apache Spark](#extended-functionality-with-apache-spark)
  - [Installing R and Python packages locally](#installing-r-and-python-packages-locally)
  - [Cleanup](#cleanup)
  - [Trouble shooting](#trouble-shooting)

## Installing the RSM-MSBA computing environment on Linux

Please follow the instructions below to install the computing environment we will use in the MSBA program on Linux (Ubuntu 18.04). The environment has R, Rstudio, Python, and Jupyter lab + plus required packages pre-installed. The environment will be consistent across all students and faculty, easy to update, and also easy to remove if desired (i.e., there will *not* be dozens of pieces of software littered all over your computer).

Important: You *must* complete the installation before our first class session on 8/6 or you will not be able to work on in-class exercises!

**Step 1**: Install docker on Ubuntu 18.04 run the following code in a terminal and provide your (sudo) password when requested: 

```bash
sudo apt install curl
source <(curl -s https://raw.githubusercontent.com/radiant-rstats/docker/master/install/install-docker.sh)
```

Detailed discussion of the steps involved is available at the link below:

https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04

Once docker is installed, make sure it is running. You can can check this by using the following command. If this produces some output and no errors you are all set to continue.

```bash
docker ps
```

![](figures/docker-icon.png)

Optional: If you are interested, the linked video gives a brief intro to what Docker is: https://www.youtube.com/watch?v=YFl2mCHdv24

**Step 2**: Open a terminal and copy-and-paste the code below.

```bash
git clone https://github.com/radiant-rstats/docker.git ~/git/docker;
cp -p ~/git/docker/launch-rsm-msba.sh ~/Desktop;
~/Desktop/launch-rsm-msba.sh;
```

This step will clone and start up a script that will finalize the installation of the computing environment. The first time you run this script it will download the latest version of the computing environment. Wait for the container to download and follow any prompts. Once the download is complete you should see a menu as in the screen shot below. You can press 2 (and Enter) to start Rstudio. Press 3 (and Enter) to start Jupyter Lab. Press q to quit. For Rstudio the username is "jovyan" and the password is "rstudio". For Jupyter the password is "jupyter"

<img src="figures/rsm-msba-menu-linux.png" width="500px">

The code above also created a copy of the file `launch-rsm-msba.sh` on your Desktop that you can use to "fire up" the container again in the future.

**Step 3**: Check that you can launch Rstudio and Jupyter

You will know that installation was successful if you can now run Rstudio and Jupyter. When you press 2 (+ enter) in the terminal, Rstudio should start up in your default web browser. If you press 3 (+ enter) Jupyter Lab should start up in another tab in your web browser. 

As mentioned above, for Rstudio the username and password are both "rstudio". For Jupyter Lab the password is "jupyter".

**Rstudio**:

<img src="figures/rsm-rstudio.png" width="500px">

**Jupyter**:

<img src="figures/rsm-jupyter.png" width="500px">

## Updating the RSM-MSBA computing environment on Linux

To update the container use the launch script and press 4 (+ enter). To update the launch script itself, press 5 (+ enter).

<img src="figures/rsm-msba-menu-linux.png" width="500px">

If for some reason you are having trouble updating either the container or the launch script open a terminal and copy-and-paste the code below. These commands will update the docker container, replace the old docker related scripts, and copy the latest version of the launch script to your Desktop.

```bash
docker pull vnijs/rsm-msba;
rm -rf ~/git/docker;
git clone https://github.com/radiant-rstats/docker.git ~/git/docker;
cp -p ~/git/docker/launch-rsm-msba.sh ~/Desktop;
```

## Connecting to postgresql

The rsm-msba container comes with <a href="http://www.postgresqltutorial.com" target="_blank">postgresql</a> installed. Once the container has been started, you can access posgresql from Rstudio using the code below:

```r
## connect to database
library(DBI)
library(RPostgreSQL)
con <- dbConnect(
  dbDriver("PostgreSQL"),
  user = "jovyan",
  host = "127.0.0.1",
  port = 8765,
  dbname = "rsm-docker",
  password = "postgres"
)

## show list of tables
dbListTables(con)
```

For a more extensive example using R see: <https://github.com/radiant-rstats/docker/blob/master/postgres/postgres-connect.md>

To access posgresql from Jupyter Lab using the code below:

```py
## connect to database
from sqlalchemy import create_engine
engine = create_engine('postgresql://jovyan:postgres@127.0.0.1:8765/rsm-docker')

## show list of tables
engine.table_names()
```

For a more extensive example using python see: <https://github.com/radiant-rstats/docker/blob/master/postgres/postgres-connect.ipynb>

## Extended functionality with Apache Spark

Run the code below from a (bash) shell to extend the functionality of the computing container with `Apache Spark`, `pyspark`, and `sparklyr`. Use the `launch-rsm-msba-spark.sh` script on your desktop to run the container

```bash
docker pull vnijs/rsm-msba-spark;
rm -rf ~/git/docker;
git clone https://github.com/radiant-rstats/docker.git ~/git/docker;
cp -p ~/git/docker/launch-rsm-msba-spark.sh ~/Desktop;
```

## Installing R and Python packages locally

To install python packages that will persist after restarting the docker container enter code like the below from the terminal in JupyterLab:

`pip3 install --user redis`

To install R packages that will persist after restarting the docker container enter code like the below in Rstudio:

`install.packages("fortunes", lib = Sys.getenv("R_LIBS_USER"))`

To remove locally installed python packages press 7 + Enter in the docker launcher menu. To remove locally installed R packages press 6 + Enter in the docker launcher menu. 

## Cleanup

To remove any prior Rstudio sessions, and locally installed R-packages, press 6 + Enter in the docker launcher menu. To remove locally installed python packages press 7 + Enter in the docker launcher menu. 

You should always stop the `rsm-msba` or `rsm-msba-spark` docker container using `q + Enter` in the docker menu. If you want a full cleanup and reset of the docker setup on your system, however, exectute the following commands from a (bash) terminal to (1) remove prior R(studio) and python settings, (2) remove all docker images, networks, and (data) volumes, and (3) 'pull' only the docker image you need (e.g., rsm-msba-spark):

```bash
rm -rf ~/.rstudio
rm -rf ~/.rsm-msba
docker system prune --all --volumes --force;
docker pull vnijs/rsm-msba-spark;
```

## Trouble shooting

The only issues we have seen on Linux so far can be "fixed" by restarting docker and/or rebooting. To restart the docker service use:

```{r}
sudo service docker stop
sudo service docker start
```
