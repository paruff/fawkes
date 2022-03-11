#!/usr/bin/env bash
# infra-k8s-boot.sh
## TODO
# conditional helm install and update based on does it exist
# break up cloud provider terraform k8s up
# os or shell conditional installs of packages mac, win , yum, apt-get?

case "$OSTYPE" in
#  linux*)   machine=Linux;;
  darwin*)  ../workspace/bootstrap.sh ;; 
# ?  win*)     machine=Windows;;
  msys*)    ../workspace/bootstrap.ps1 ;;
#  cygwin*)  machine=Cygwin;;
#  bsd*)     machine=BSD;;
  *)        echo "unknown: $OSTYPE" ;;
esac

# echo OS Identified as ${machine}

# if [ ${machine} = "MacOS" ]; 
# then
# ../../workspace/bootstrap.sh
# fi

# # now for windows 10 running git bash
# # TODO define and lock the versions to working versions 
# if [ ${machine} = "GBash" ]; 
# then
# ../../workspace/bootstrap.ps1
# fi

# IAC a vpc and k8s cluster 
buildinfra.sh


buildplatform.sh
