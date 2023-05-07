# docker-sdp-perforce-server-for-unreal-engine

Docker perforce server using SDP, configured for Unreal Engine.

## How to use

### Build the image

Use the prebuilt one from Docker Hub:[zhaojunmeng/sdp-perforce-server-for-unreal-engine](https://registry.hub.docker.com/r/zhaojunmeng/sdp-perforce-server-for-unreal-engine/)

or build it yourself:

```bash

docker build . -t perforce-sdp-server-for-unreal-engine:r22.2 --no-cache
    
```

If you want to run the image on NAS, you must save the image as a tar file, and load it on the NAS:

```bash
docker save perforce-sdp-server-for-unreal-engine:r22.2 -o perforce-sdp-server-for-unreal-engine-r22.2.tar
```

### Run the image

The first time you run a SDP instance, you must login as user 'perforce' using P4Admin, and change the default password.

## Disclaimer

I decline any responsibility in case of data loss or in case of a difficult (or even impossible) maintenance if you use this solution.  
I did this as a hobby for a small project.  
If you still want to use it for your project, I would suggest to setup or to do regularly backups of your project.
