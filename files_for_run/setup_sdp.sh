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
   msg "Running: $cmd"
   $cmd
   CMDEXITCODE=$?
   return $CMDEXITCODE
}

# Part of this script follows the instructions:
# https://swarm.workshop.perforce.com/projects/perforce-software-sdp/view/main/doc/SDP_Guide.Unix.html#_manual_install

HxDepots=/hxdepots

# 11. Set environment variable SDP.
export SDP=${HxDepots}/sdp

# Check if SDP has installed.
SDPVersionFile=${SDP}/Version
msg "Check ${SDPVersionFile} existance."

if [ ! -e ${SDPVersionFile} ]; then
   msg "Installing SDP"

   # 10. Extract the SDP tarball.
   DownloadsDir=/usr/local/bin
   cd ${HxDepots}
   run "tar -xzpf ${DownloadsDir}/sdp.Unix.tgz" "Unpacking ${DownloadsDir}/sdp.Unix.tgz in ${PWD}." ||\
      bail "Failed to untar SDP tarfile."

   # 12. Make the entire $SDP (/hxdepots/sdp) directory writable by perforce:perforce with this command:
   chmod -R +w ${SDP}

   # 13. Copy every existing p4 binaries into SDP folder.
   if [ -d "${DownloadsDir}/helix_binaries/" ]; then
      run "mv ${DownloadsDir}/helix_binaries/* ${SDP}/helix_binaries/"
   fi
else
   msg "SDP already installed, version:"
   cat ${SDPVersionFile}
fi

# Check if the P4 Instance has configured.
P4DInstanceScript=/p4/${SDP_INSTANCE}/bin/p4d_${SDP_INSTANCE}
msg "Check ${P4DInstanceScript} existance."

if [ ! -e ${P4DInstanceScript} ]; then
   # Configure for new instance
   # This part references from:
   # https://swarm.workshop.perforce.com/projects/perforce_software-helix-installer/files/main/src/reset_sdp.sh

   msg "Configuring new SDP instance: ${SDP_INSTANCE}"
   declare SDPSetupDir="${SDP}/Server/Unix/setup"
   cd "${SDPSetupDir}" || bail "Could not cd to [${SDPSetupDir}]."
   
   # 1. Call mkdirs.sh first.
   CfgDir=/usr/local/bin
   MkdirsCfgPath=${CfgDir}/mkdirs.unreal.cfg
   cp -p ${MkdirsCfgPath} mkdirs.${SDP_INSTANCE}.cfg

   # change the password in mkdirs.cfg
   sed -e "s:=adminpass:=${P4_PASSWD}:g" \
      -e "s:=servicepass:=${P4_PASSWD}:g" \
      -e "s:=DNS_name_of_master_server_for_this_instance:=${P4_MASTER_HOST}:g" \
      ${MkdirsCfgPath} > mkdirs.${SDP_INSTANCE}.cfg

   chmod +x mkdirs.sh

   msg "\\nSDP Localizations in mkdirs.cfg:"
   diff mkdirs.${SDP_INSTANCE}.cfg mkdirs.cfg

   run "./mkdirs.sh ${SDP_INSTANCE}"

   # Read P4ROOT/P4BIN
   source /p4/common/bin/p4_vars ${SDP_INSTANCE}

   # 2. Config for unicode
   if [ "${UNICODE_SERVER}" = "1" ]; then
      # See https://www.perforce.com/manuals/p4sag/Content/P4SAG/superuser.unicode.setup.html
      run "sudo -u perforce ${P4DInstanceScript} -r ${P4ROOT} -xi" \
         "Set Unicode (p4d -xi) for instance ${SDP_INSTANCE}." ||\
         bail "Failed to set Unicode."
   fi
   
   # 3. Call configure_new_server.sh
   # This part references from:
   # https://swarm.workshop.perforce.com/projects/perforce_software-helix-installer/files/main/src/configure_sample_depot_for_sdp.sh

   # We must start the service before run configure_new_server.sh
   /p4/${SDP_INSTANCE}/bin/p4d_${SDP_INSTANCE}_init start

   run "${P4BIN} -s info -s" "Verifying direct connection to Perforce server." ||\
      bail "Could not connect to Perforce server."

   cd "${HxDepots}/sdp/Server/setup" ||\
      bail "Failed to cd to [${HxDepots}/sdp/Server/setup]."

   ConfigureNewServerBak="configure_new_server.sh.$(date +'%Y%m%d-%H%M%S').bak"
   run "mv -f configure_new_server.sh ${ConfigureNewServerBak}" \
      "Tweaking configure_new_server.sh settings to values more appropriate, e.g. reducing 5G storage limits." ||\
      bail "Failed to move configure_new_server.sh to ${ConfigureNewServerBak}."

   # Warning: If the values in configure_new_server.sh are changed from 5G, this will need to be updated.
   sed -e 's/filesys.P4ROOT.min=5G/filesys.P4ROOT.min=10M/g' \
      -e 's/filesys.depot.min=5G/filesys.depot.min=10M/g' \
      -e 's/filesys.P4JOURNAL.min=5G/filesys.P4JOURNAL.min=10M/g' \
      "${ConfigureNewServerBak}" >\
      configure_new_server.sh ||\
      bail "Failed to do sed substitutions in ${HxDepots}/sdp/Server/setup/${ConfigureNewServerBak}"

   run "chmod -x ${ConfigureNewServerBak}"
   run "chmod +x configure_new_server.sh"

   msg "Changes made to configure_new_server.sh:"
   diff "${ConfigureNewServerBak}" configure_new_server.sh
   
   run "./configure_new_server.sh ${SDP_INSTANCE}" \
      "Applying SDP configurables." ||\
      bail "Failed to set SDP configurables. Aborting."

   # This part references configure-helix-p4d.sh, see
   # https://www.perforce.com/manuals/p4sag/Content/P4SAG/install.linux.packages.configure.html
   ADMINUSER=perforce

   # Populating the typemap
   ${P4BIN} typemap -i < ${CfgDir}/typemap.unreal.cfg
   
   # Initializing protections table.
   # In the pr-protect.cfg file, except user perforce, no other user of group can access depot by default.
   ${P4BIN} protect -i < ${CfgDir}/p4-protect.cfg
   
   # Setting password
   ${P4BIN} passwd -P ${P4_PASSWD} ${ADMINUSER}
   export P4PASSWD=${P4_PASSWD}
   
   # Setting security level to 3 (high)
   # This will cause existing passwords reset.
   run "${P4BIN} configure set security=3"
   
   # 4. Finish
   /p4/${SDP_INSTANCE}/bin/p4d_${SDP_INSTANCE}_init stop
else
   msg "Skip exiting instance configuring:"
   run "cat ${P4DInstanceScript}"
fi

run "sudo -u perforce crontab /p4/p4.crontab.${SDP_INSTANCE}"

# Verify the instance.
# Skip p4t_files, because after "configure set security=3", user need to reset password to login, so no tickets file.
/p4/common/bin/verify_sdp.sh ${SDP_INSTANCE} -skip license,offline_db,p4t_files
