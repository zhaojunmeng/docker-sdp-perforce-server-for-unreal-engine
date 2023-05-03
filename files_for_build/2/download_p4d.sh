#!/bin/bash
set -u

# This script uses get_helix_binaries.sh, which is downloaded from:
# https://swarm.workshop.perforce.com/projects/perforce-software-sdp/files/main/helix_binaries/get_helix_binaries.sh

# get_helix_binaries.sh need USER variable
export USER=$(whoami)

# get_helix_binaries.sh need to run in */sdp/helix_binaries/ folder
BinaryDownloadDir=/tmp/sdp/helix_binaries
cd ${BinaryDownloadDir}

/bin/bash -x ${BinaryDownloadDir}/get_helix_binaries.sh -r ${P4Version} -b ${P4BinList}

# copy our download files into another folder.
BinarySaveDir=/usr/local/bin/helix_binaries
mkdir ${BinarySaveDir}
for binary in $(echo "${P4BinList}"|tr ',' ' '); do mv -v ${BinaryDownloadDir}/${binary} ${BinarySaveDir}; done