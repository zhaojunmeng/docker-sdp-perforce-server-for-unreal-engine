### Base image with SDP prerequisites.
# Multi stage build is more cache friendly, modify part of the Dockerfile will not cause all the files to be redownloaded.

# For which ubuntu version perforce supported, see:
# https://www.perforce.com/manuals/p4sag/Content/P4SAG/install.linux.packages.html
ARG OS_DISTRO=jammy
FROM ubuntu:${OS_DISTRO} as base

##  Install system prerequisites used by SDP.
# 1. cron: for running SDP cron jobs
# 2. curl: for downloading SDP
# 3. file: used by verify_sdp.sh
# 4. mailutils: SDP maintance script will call mail command
# 5. sudo: for running commands as another user
RUN apt-get update && apt-get install -y \
    cron \
    curl \
    file \
    mailutils \
    sudo \
 && rm -rf /var/lib/apt/lists/*

### Download SDP stage
FROM base as stage1

COPY files_for_build/1/* /tmp

# Specify the SDP version, if SDP_VERSION is empty, the latest SDP will be downloaded.
ARG SDP_VERSION=.2023.1.29621

# Download SDP
RUN /bin/bash -x /tmp/setup_container.sh\
&& export SDPVersion=$SDP_VERSION \
&& /bin/bash -x /tmp/download_sdp.sh \
&& rm -rf /tmp/*

### Download Helix binaries stage
FROM stage1 as stage2

# P4 binaries version
ARG P4_VERSION=r23.1

# For minal usage, only p4 and p4d need to be downloaded.
ARG P4_BIN_LIST=p4,p4d

COPY files_for_build/2/* /tmp/sdp/helix_binaries/

RUN export P4Version=${P4_VERSION}\
&& export P4BinList=${P4_BIN_LIST}\
&& /bin/bash -x /tmp/sdp/helix_binaries/download_p4d.sh\
&& rm -rf /tmp/*

### Final stage
FROM stage2 as stage3

# Port for perforce server
EXPOSE 1666

# The meaning of each volumn, see:
# https://swarm.workshop.perforce.com/projects/perforce-software-sdp/view/main/doc/SDP_Guide.Unix.html#_volume_layout_and_hardware
VOLUME [ "/hxmetadata", "/hxdepots", "/hxlogs", "/p4" ]

COPY --chmod=0755 files_for_run/* /usr/local/bin/

# For first running a P4 Instance，you can change the default P4_PASSWD variable.
# P4_PASSWD is used for init perforce instance, 
# after "configure set security=3" is called, when you login to Perforce server for the first time, you will be asked to change the password.
ENV SDP_INSTANCE=1 P4_PASSWD=F@stSCM! UNICODE_SERVER=1 P4_MASTER_HOST=127.0.0.1

ENTRYPOINT ["/usr/local/bin/docker_entry.sh"]