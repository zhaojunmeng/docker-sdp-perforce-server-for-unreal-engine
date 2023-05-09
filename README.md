# docker-sdp-perforce-server-for-unreal-engine

Docker perforce server using SDP([Server Deployment Package](https://swarm.workshop.perforce.com/projects/perforce-software-sdp)), configured for Unreal Engine(a unicode, case-insensitive Perforce server with Unreal Engine's recommended Typemap).

## How to use

### 1. Get the Docker image

You can get the Docker image from Docker Hub or build it yourself.

* #### Use prebuilt image

You can use the prebuilt image from Docker Hub: [zhaojunmeng/sdp-perforce-server-for-unreal-engine](https://registry.hub.docker.com/r/zhaojunmeng/sdp-perforce-server-for-unreal-engine/)

* #### Build it yourself

In the project root directory, use the following command to build the image using p4d version r22.2

```bash

docker build . -t perforce-sdp-server-for-unreal-engine:r22.2 --no-cache
    
```

If you want to run the image on NAS, you must save the image as a tar file, so you can upload it to the NAS.

```bash
docker save perforce-sdp-server-for-unreal-engine:r22.2 -o perforce-sdp-server-for-unreal-engine-r22.2.tar
```

### 2. Run the image

The first time you run a SDP instance, you must login as user 'perforce' using P4Admin, and change the default password.

Details on how to run:

### 3. Customize



## Disclaimer

I decline any responsibility in case of data loss or in case of a difficult (or even impossible) maintenance if you use this solution.  
I did this as a hobby for a small project.  
If you still want to use it for your project, I would suggest to setup or to do regularly backups of your project.
