#!/bin/bash

# This script follows the instructions:
# https://swarm.workshop.perforce.com/projects/perforce-software-sdp/view/main/doc/SDP_Guide.Unix.html#_manual_install

OSUSER_HOME=/home/perforce

# This script sets up the base docker container.
# It expects to be run as root within the container.

# 1.
# Create a group called perforce
groupadd perforce

# 2.
# Create a user called perforce and set the user’s home directory
useradd -d ${OSUSER_HOME} -g perforce -m -s /bin/bash perforce

# 3.
# Allow the perforce user sudo access
sudo touch /etc/sudoers.d/perforce
sudo chmod 0600 /etc/sudoers.d/perforce
sudo echo "perforce ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/perforce
sudo chmod 0400 /etc/sudoers.d/perforce