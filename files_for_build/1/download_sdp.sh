#!/bin/bash
set -u

#------------------------------------------------------------------------------
# Functions msg(), dbg(), and bail().
# Sample Usage:
#    bail "Missing something important. Aborting."
#    bail "Aborting with exit code 3." 3
function msg () { echo -e "$*"; }
function warnmsg () { msg "\\nWarning: ${1:-Unknown Warning}\\n"; WarningCount+=1; }
function errmsg () { msg "\\nError: ${1:-Unknown Error}\\n"; ErrorCount+=1; }
function dbg () { msg "DEBUG: $*" >&2; }
function bail () { errmsg "${1:-Unknown Error}"; exit "${2:-1}"; }

#------------------------------------------------------------------------------
# Functions run($cmd, $desc)
#
# This function is similar to functions defined in SDP core libraries, but we
# need to duplicate them here since this script runs before the SDP is
# available on the machine (and we require dependencies for this
# script).
function run {
   cmd="${1:-echo Testing run}"
   desc="${2:-}"
   [[ -n "$desc" ]] && msg "$desc"
   msg " Running: $cmd"
   $cmd
   CMDEXITCODE=$?
   return $CMDEXITCODE
}

# The download part is referenced from:
# https://swarm.workshop.perforce.com/projects/perforce_software-helix-installer/files/main/src/reset_sdp.sh

# If SDPVersion is empty, the latest version of SDP will be downloaded.
SDPVersion=${$SDPVersion:-}
SDPTar="sdp.Unix${SDPVersion}.tgz"
SDPURL="https://swarm.workshop.perforce.com/projects/perforce-software-sdp/download/downloads/${SDPTar}"

DownloadsDir="/usr/local/bin"
if [[ ! -d "${DownloadsDir}" ]]; then
    run "/bin/mkdir -p ${DownloadsDir}"
fi

cd "${DownloadsDir}" || bail "Could not cd to downloads dir: ${DownloadsDir}"
run "curl -k -s -O ${SDPURL}" || bail "Could not get SDP tar file from [${SDPURL}]."

# Rename file without version in file name, for easier use later on.
mv ${SDPTar} sdp.Unix.tgz