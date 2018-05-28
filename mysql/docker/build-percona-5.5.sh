#!/bin/bash

type=$1
if [ "$type" = "master" ]; then
  cp my-master.cnf percona-5.5/my.cnf
elif [ "$type" = "slave" ]; then
  cp my-slave.cnf percona-5.5/my.cnf
else
  echo "$0 [master|slave]"
  exit 1
fi


docker build -rm -t registry.ecg.so/gtau/percona_5.5:${type} percona-5.5/
docker push registry.ecg.so/gtau/percona_5.5:${type}
