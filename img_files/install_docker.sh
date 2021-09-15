#!/bin/bash

sudo -E apt-get -y install apt-transport-https ca-certificates software-properties-common
curl -sL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
arch=$(dpkg --print-architecture)
sudo -E add-apt-repository "deb [arch=${arch}] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo -E apt-get update
sudo -E apt-get -y install docker-ce docker-compose

