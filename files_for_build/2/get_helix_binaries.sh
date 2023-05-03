#!/bin/bash
#==============================================================================
# Copyright and license info is available in the LICENSE file included with
# the Server Deployment Package (SDP), and also available online:
# https://swarm.workshop.perforce.com/projects/perforce-software-sdp/view/main/LICENSE
#------------------------------------------------------------------------------
set -u

# This script acquires Perforce Helix binaries from the Perforce FTP server.
# For documentation, run: get_helix_binaries.sh -man

#==============================================================================
# Declarations and Environment

declare ThisScript=${0##*/}
declare Version=1.3.3
declare -i NoOp=0
declare -i ErrorCount=0
declare -i WarningCount=0
declare -i RetryCount=0
declare -i RetryMax=2
declare -i RetryDelay=2
declare -i RetryOK=0
declare HelixVersion=
declare BinList=
declare Platform=linux26x86_64
declare PerforceFTPBaseURL="https://ftp.perforce.com/perforce"
declare BinURL=
declare Cmd=
declare DefaultHelixVersion=r22.2
declare DefaultBinList="p4 p4d p4broker p4p"

function msg () { echo -e "$*"; }
function errmsg () { msg "\\nError: ${1:-Unknown Error}\\n"; ErrorCount+=1; }
function warnmsg () { msg "\\nWarning: ${1:-Unknown Warning}\\n"; WarningCount+=1; }
function bail () { errmsg "${1:-Unknown Error}"; exit "${2:-1}"; }

#------------------------------------------------------------------------------
# Function: usage (required function)
#
# Input:
# $1 - style, either -h (for short form) or -man (for man-page like format).
# The default is -h.
#
# $2 - error message (optional).  Specify this if usage() is called due to
# user error, in which case the given message displayed first, followed by the
# standard usage message (short or long depending on $1).  If displaying an
# error, usually $1 should be -h so that the longer usage message doesn't
# obscure the error message.
#
# Sample Usage:
# usage 
# usage -man
# usage -h "Incorrect command line usage."
#
# This last example generates a usage error message followed by the short
# '-h' usage summary.
#------------------------------------------------------------------------------
function usage {
   declare style=${1:--h}
   declare errorMessage=${2:-Unset}

   if [[ $errorMessage != Unset ]]; then
      msg "\\n\\nUsage Error:\\n\\n$errorMessage\\n\\n"
   fi

msg "USAGE for $ThisScript v$Version:

$ThisScript [-r <HelixMajorVersion>] [-b <Binary1>,<Binary2>,...] [-n] [-D]

   or

$ThisScript -h|-man"
   if [[ $style == -man ]]; then
      msg "
DESCRIPTION:
	This script acquires Perforce Helix binaries from the Perforce FTP server.

	The four Helix binaries that can be acquired are:

	* p4, the command line client
	* p4d, the Helix Core server
	* p4p, the Helix Proxy
	* p4broker, the Helix Broker

	This script gets the latest patch of binaries for the current major Helix
	version.  It is intended to acquire the latest patch for an existing install,
	or to get initial binaries for a fresh new install.  It must be run from
	the /hxdepots/sdp/helix_binaries directory (or similar; the /hxdepots
	directory is the default but is subject to local configuration).

	The helix_binaries directory is used for staging binaries for later upgrade
	with the SDP 'upgrade.sh' script (documented separately).  This helix_binaries
	directory is used to stage binaries on the current machine, while the
	'upgrade.sh' script updates a single SDP instance (of which there might be
	several on a machine).

	The helix_binaries directory may not be in the PATH. As a safety feature,
	the 'verify_sdp.sh' will report an error if the 'p4d' binary is found outside
	/p4/common/bin in the PATH. The SDP 'upgrade.sh' check uses 'verify_sdp.sh'
	as part of its preflight checks, and will refuse to upgrade if any 'p4d' is
	found outside /p4/common/bin.

	When a newer major version of Helix binaries is needed, this script should not
	be modified directly. Instead, the recommended approach is to upgrade the SDP
	to get the latest version of SDP first, which will included a newer version of
	this script, as well as the latest 'upgrade.sh'.  The 'upgrade.sh' script
	is updated with each major SDP version to be aware of any changes in
	the upgrade procedure for the corresponding p4d version.  Upgrading SDP first
	ensures you have a version of the SDP that works with newer versions of p4d
	and other Helix binaries.

OPTIONS:
 -r <HelixMajorVersion>
	Specify the Helix Version, using the short form.  The form is rYY.N, e.g. r20.2
	to denote the 2020.2 release. The default: is $DefaultHelixVersion

 -b <Binary1>[,<Binary2>,...]
	Specify a comma-delimited list of Helix binaries. The default is: $DefaultBinList

 -n	Specify the '-n' (No Operation) option to show the commands needed
	to fetch the Helix binaries from the Perforce FTP server without attempting
	to execute them.

 -D	Set extreme debugging verbosity using bash 'set -x' mode.

HELP OPTIONS:
 -h	Display short help message
 -man	Display this manual page

EXAMPLES:
	Note: All examples assume the SDP is in the standard location, /hxdepots/sdp.

	Example 1 - Typical Usage with no arguments:

	cd /hxdepots/sdp/helix_binaries
	./get_helix_binaries.sh

	This acquires the latest patch of all 4 binaries for the $DefaultHelixVersion
	release (aka 20${DefaultHelixVersion#r}).

	Example 2 - Specifying the major version:

	cd /hxdepots/sdp/helix_binaries
	./get_helix_binaries.sh -r r19.2

	This gets the latest patch of for the 2019.2 release of all 4 binaries.

	Note: Only supported Helix binaries are guaranteed to be available from the
	Perforce FTP server.

	Note: Only the latest patch of any given binary is available from the Perforce
	FTP server.

	Example 3 - Sample getting r20.2 and skipping the proxy binary (p4p):

	cd /hxdepots/sdp/helix_binaries
	./get_helix_binaries.sh -r r20.2 -b p4,p4d,p4broker

DEPENDENCIES:
	This script requires outbound internet access. Depending on your environment,
	it may also require HTTPS_PROXY to be defined, or may not work at all.

	If this script doesn't work due to lack of outbound internet access, it is
	still useful illustrating the locations on the Perforce FTP server where
	Helix Core binaries can be found.  If outbound internet access is not
	available, use the '-n' flag to see where on the Perforce FTP server the
	files must be pulled from, and then find a way to get the files from the
	Perforce FTP server to the correct directory on your local machine,
	/hxdepots/sdp/helix_binaries by default.

EXIT CODES:
	An exit code of 0 indicates no errors were encountered. An
	non-zero exit code indicates errors were encountered.
"
   fi

   exit 1
}

#==============================================================================
# Command Line Processing

declare -i shiftArgs=0

set +u
while [[ $# -gt 0 ]]; do
   case $1 in
      (-h) usage -h;;
      (-man) usage -man;;
      (-r) HelixVersion="${2:-}"; shiftArgs=1;;
      (-b) BinList="${2:-}"; shiftArgs=1;;
      (-n) NoOp=1;;
      (-D) set -x;; # Debug; use 'set -x' mode.
      (*) usage -h "Unknown command line fragment [$1].";;
   esac

   # Shift (modify $#) the appropriate number of times.
   shift; while [[ $shiftArgs -gt 0 ]]; do
      [[ $# -eq 0 ]] && usage -h "Incorrect number of arguments."
      shiftArgs=$shiftArgs-1
      shift
   done
done
set -u

[[ -n "$HelixVersion" ]] || HelixVersion="$DefaultHelixVersion"
[[ -n "$BinList" ]] || BinList="$DefaultBinList"

#==============================================================================
# Command Line Verification

[[ "$PWD" == *"/sdp/helix_binaries" ]] || usage -h "\\n\\tThis $ThisScript script must be run\\n\\tfrom the <SDPInstallroot>/sdp/helix_binaries directory, e.g.\\n\\t/hxdepots/sdp/helix_binaries. The current directory is:\\n\\t$PWD"

if [[ ! "$HelixVersion" =~ ^r[0-9]{2}\.[0-9]{1}$ ]]; then
   usage -h "\\n\\tThe Helix Version specified with '-r $HelixVersion' is invalid.\\n\\tIt should look like: $DefaultHelixVersion\\n"
fi

#==============================================================================
# Main Program

msg "\\nStarted $ThisScript v$Version as $USER@${HOSTNAME%%.*} at $(date)."

for binary in $(echo "$BinList"|tr ',' ' '); do
   msg "\\nGetting $binary ..."
   BinURL="${PerforceFTPBaseURL}/${HelixVersion}/bin.${Platform}/$binary"
   if [[ -f "$binary" ]]; then
      chmod +x "$binary"
      msg "Old version of $binary: $("./$binary" -V | grep Rev)"

      if [[ "$NoOp" -eq 0 ]]; then
         rm -f "$binary"
      fi
   fi

   Cmd="curl -s -k -O $BinURL"

   if [[ "$NoOp" -eq 1 ]]; then
      msg "NoOp: Would run: $Cmd"
      continue
   else
      msg "Running: $Cmd"
   fi

   if $Cmd; then
      chmod +x "$binary"
      msg "New version of $binary: $("./$binary" -V | grep Rev)"
   else
      # Replace the '-s' silent flag with '-v' after we have had an error, to
      # help with debugging.
      Cmd="curl -v -k -O $BinURL"
      warnmsg "Failed to download $binary with this URL: $BinURL\\nRetrying ..."
      RetryCount+=0

      while [[ "$RetryCount" -le "$RetryMax" ]]; do
         RetryCount+=1
         sleep "$RetryDelay"
         msg "Retry $RetryCount of $binary with command: $Cmd"
         if $Cmd; then
            chmod +x "$binary"
            msg "New version of $binary: $("./$binary" -V | grep Rev)"
            RetryOK=1
            break
         else
            warnmsg "Retry $RetryCount failed again to download $binary with this URL: $BinURL"
         fi
      done

      if [[ "$RetryOK" -eq 0 ]]; then
         errmsg "Failed to download $binary with this URL: $BinURL"
         rm -f "$binary"
      fi
   fi
done

if [[ "$ErrorCount" -eq 0 ]]; then
   msg "\\nDownloading of Perforce Helix binaries completed OK."
else
   errmsg "\\There were $ErrorCount errors attempting to download Perforce Helix binaries."
fi

exit "$ErrorCount"
