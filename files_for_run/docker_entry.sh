#!/bin/bash
set -u

# Stop perforce service.
function exit_script(){
  echo "Caught SIGTERM"
  /p4/${SDP_INSTANCE}/bin/p4d_${SDP_INSTANCE}_init stop
  exit 0
}

# Trap the SIGTERM signal so we can gracefully stop perforce service when docker stop is called.
trap exit_script SIGTERM

# Set up the SDP instance if nessessary.
bash /usr/local/bin/setup_sdp.sh

# Start perforce service.
/p4/${SDP_INSTANCE}/bin/p4d_${SDP_INSTANCE}_init start

#--- send sleep into the background, then wait for it.
sleep infinity &
#--- "wait" will wait until the command you sent to the background terminates, which will be never.
#--- "wait" is a bash built-in, so bash can now handle the signals sent by "docker stop"
wait