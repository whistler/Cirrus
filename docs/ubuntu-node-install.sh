#!/bin/sh
#
# This script installs nodejs, coffeescript and git on an Ubuntu machine
# so that this project can be run. Tested on Ubuntu 12.04 LTS.

# install node prereqs
sudo apt-get install python-software-properties python g++ make
 
# install node
wget http://nodejs.org/dist/v0.10.12/node-v0.10.12.tar.gz
tar xzvf node-v0.10.12.tar.gz 
cd node-v0.10.12/
./configure
make 
sudo make install
 
# install coffee-script
sudo npm -g install coffee-script