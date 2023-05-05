# 如何在Docker上，搭建Perforce服务器，版本控制Unreal项目

副标题：自己动手，在群晖上，用Docker搭建Perforce服务器，用来版本控制Unreal项目

## 前言

首先，在群晖上，利用Docker搭建Perforce服务器的类似文章，是可以搜到的，但是这些搭建方法，都有一些不满足我的需求。

| 链接                                                                                              | 描述  | 缺点 |
| ------------------------------------------------------------------------------------------------- | ----- | - |
| [Making a Perforce Server With Docker](https://aricodes.net/posts/perforce-server-with-docker/)                                                                                         | "It also places files all over the system."  | "I do not personally use Perforce and devised this tutorial for a friend"<br> 作者自己不用Perforce，大家就随便一看吧 |
| [Setting Up Perforce with Docker for Unreal Engine 4](https://www.froyok.fr/blog/2018-09-setting-up-perforce-with-docker-for-unreal-engine-4/) | 这篇文章比较全面 |  |
| [Using Perforce as Source Control](https://docs.unrealengine.com/5.1/en-US/using-perforce-as-source-control-for-unreal-engine/)                                                                                         | UE的官方文档 "case-insensitive Perforce server" "P4 Typemap"  |  |
| [How Docker Works with Helix Core](https://www.perforce.com/blog/vcs/how-docker-works)                        | Perforce自己官方并没有一个Docker的image<br> 文章讲了官方自己做的在Docker和非Docker环境部署的性能差异 | |
| [perforce_software / SDP](https://swarm.workshop.perforce.com/projects/perforce-software-sdp)                        | Server Deployment Package (SDP) | |
| [Perforce Helix Installer](https://swarm.workshop.perforce.com/projects/perforce_software-helix-installer)                        | Perforce Helix Installer | "Please DO NOT contact Perforce Support for the Helix Installer, as it is not an officially supported product offering." <br> 这个项目不是官方支持的|

在群晖的Docker中，搜索image，关键词perforce，可以搜到几个结果

| 链接                             | 描述 | 不满足我需求的点 | DockerImage |
| -------------------------------- | ----- | - | - |
| [ambakshi/docker-perforce](https://github.com/ambakshi/docker-perforce) | 使用人最多的一个perforce docker image <br>基于centos系统 | 最后是2018.2版本的P4 | [ambakshi/perforce-server](https://registry.hub.docker.com/r/ambakshi/perforce-server) |
| [Froyok/froyok-perforce](https://github.com/Froyok/froyok-perforce)                        | 在上面的基础上，增加了case, typemap  | | no |
| [MothDoctor/docker-perforce](https://github.com/MothDoctor/docker-perforce)                        | 在上面的基础上，增加了case, typemap 2022.1 <br>[Using and setting up Perforce repository](https://dev.epicgames.com/community/learning/tutorials/Gxoj/unreal-engine-using-and-setting-up-perforce-repository#unreal-specific-typemap-5) | | [mothdoctor/perforce-server-unreal](https://registry.hub.docker.com/r/mothdoctor/perforce-server-unreal/) |
| [HaberkornJonas/Perforce-Server-On-Docker-For-Unreal](https://github.com/HaberkornJonas/Perforce-Server-On-Docker-For-Unreal)                        | 参考了上面的仓库  | | no |
| [XistGG/docker-perforce-server-for-unreal-engine](https://github.com/XistGG/docker-perforce-server-for-unreal-engine)                        | 参考了前两个的仓库 基于ubuntu系统  | | no |
