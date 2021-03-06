#!/bin/bash

set -e

UNAME=$(uname | tr "[:upper:]" "[:lower:]")
if [ "$UNAME" == "linux" ]; then
  if [ -f /etc/lsb-release ]; then
    DISTRO=$(cat /etc/lsb-release | grep DISTRIB_ID | cut -d'=' -f2 | tr "[:upper:]" "[:lower:]")
  elif [ -d /etc/lsb-release.d ]; then
    DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'// | tr "[:upper:]" "[:lower:]")
  elif [ -f /etc/redhat-release ]; then
    DISTRO=redhat
  fi
fi

case $DISTRO in
  ubuntu)
    echo "# Installing dependencies for native extensions: libssh2-1-dev libssl-dev cmake pkg-config"
    sudo apt-get install -y libssh2-1-dev libssl-dev cmake pkg-config
    echo
    ;;
  redhat)
    echo "# Installing dependencies for native extensions: libssh2-devel openssl-devel cmake pkgconfig"
    sudo yum install -y libssh2-devel openssl-devel cmake pkgconfig
    echo
    ;;
esac


echo "# Installing dapp gem"

DAPP_VERSION=$1

gem install dapp $(if [[ $DAPP_VERSION ]] ; then echo "--version=$DAPP_VERSION" ; fi)
echo

if [ -z $DAPP_VERSION ]; then
  DAPP_VERSION=$(dapp --version | cut -d' ' -f2)
fi


echo "# Installing dapp update cron job into /etc/cron.d/dapp-update"

sudo mkdir -p /etc/cron.d

echo "* * * * * $USER /bin/bash -lec 'dapp update'" | sudo tee /etc/cron.d/dapp-update
