# 自己动手，在(NAS)群晖上，用Docker搭建Perforce服务器，版本控制Unreal项目

## 需求分析

我的需求是，在自己的NAS(群晖)上，搭建一个Perforce服务器，用来版本控制Unreal项目。

第一步肯定是搜索网上现有的资料，下面是我搜索到的内容：

+ [Using Perforce as Source Control](https://docs.unrealengine.com/5.1/en-US/using-perforce-as-source-control-for-unreal-engine/)

Unreal的官方文档，其中重要的关键词是：

"a case-insensitive Perforce server"

"set up your P4 Typemap so Perforce knows how to treat Unreal file types"

+ [Setting Up Perforce with Docker for Unreal Engine 4](https://www.froyok.fr/blog/2018-09-setting-up-perforce-with-docker-for-unreal-engine-4/)

跟随上面的case-insensitive, Typemap关键词，搜索到的比较全面的一片文章，并且在GitHub上面开源了([Froyok/froyok-perforce](https://github.com/Froyok/froyok-perforce))，如果我不多搜索一下，可能基本上就会选择这个方案来做了。

+ [Making a Perforce Server With Docker](https://aricodes.net/posts/perforce-server-with-docker/)

这篇是我和上面同时搜到的文章，这个文章里面的方案我不建议使用，主要是因为作者其实自己平时不使用Perforce：
> I do not personally use Perforce and devised this tutorial for a friend

但是，文章里面却提到了一些比较关键的点：

> It also places files all over the system. You can configure a data directory, but its database is initialized from where the start command is run instead of in a dedicated location and all non-volume files in a Docker container are ephemeral.

作者根据上面的结论，自己写的Dockerfile，分了2个volumes，而前一篇文章的方案，只分配了一个volume。基于这个不同点，就让我出发去寻找到底怎么分配volume才是合理的方案。

| 链接                                                                                              | 描述  | 缺点 |
| ------------------------------------------------------------------------------------------------- | ----- | - |
| [How Docker Works with Helix Core](https://www.perforce.com/blog/vcs/how-docker-works)                        | Perforce自己官方并没有一个Docker的image<br> 文章讲了官方自己做的在Docker和非Docker环境部署的性能差异 | |
| [perforce_software / SDP](https://swarm.workshop.perforce.com/projects/perforce-software-sdp)                        | Server Deployment Package (SDP) | |
| [Perforce Helix Installer](https://swarm.workshop.perforce.com/projects/perforce_software-helix-installer)                        | Perforce Helix Installer | "Please DO NOT contact Perforce Support for the Helix Installer, as it is not an officially supported product offering." <br> 这个项目不是官方支持的|

在群晖的Docker中，搜索image，关键词perforce，可以搜到几个结果

| 链接                             | 描述 | 不满足我需求的点 | DockerImage |
| -------------------------------- | ----- | - | - |
| [ambakshi/docker-perforce](https://github.com/ambakshi/docker-perforce) | 使用人最多的一个perforce docker image <br>基于centos系统 | 最后是2018.2版本的P4 | [ambakshi/perforce-server](https://registry.hub.docker.com/r/ambakshi/perforce-server) |
| [Froyok/froyok-perforce](https://github.com/Froyok/froyok-perforce)                        | 在上面的基础上，增加了case, typemap，上面文章的GitHub仓库  | | no |
| [MothDoctor/docker-perforce](https://github.com/MothDoctor/docker-perforce)                        | 在上面的基础上，增加了case, typemap 2022.1 <br>[Using and setting up Perforce repository](https://dev.epicgames.com/community/learning/tutorials/Gxoj/unreal-engine-using-and-setting-up-perforce-repository#unreal-specific-typemap-5) | | [mothdoctor/perforce-server-unreal](https://registry.hub.docker.com/r/mothdoctor/perforce-server-unreal/) |
| [HaberkornJonas/Perforce-Server-On-Docker-For-Unreal](https://github.com/HaberkornJonas/Perforce-Server-On-Docker-For-Unreal)                        | 参考了上面的仓库  | | no |
| [XistGG/docker-perforce-server-for-unreal-engine](https://github.com/XistGG/docker-perforce-server-for-unreal-engine)                        | 参考了前两个的仓库 基于ubuntu系统  | | no |

## 需求总结

## 源码

构建好可以直接使用的Docker Image在这里(也可以直接在Docker里面搜索到)：
[zhaojunmeng/sdp-perforce-server-for-unreal-engine](https://registry.hub.docker.com/r/zhaojunmeng/sdp-perforce-server-for-unreal-engine/)

源代码在这里：
[zhaojunmeng/docker-sdp-perforce-server-for-unreal-engine](https://github.com/zhaojunmeng/docker-sdp-perforce-server-for-unreal-engine)

## 实现选型

关于源码本身，我添加了比较详细的注释，细节大家看代码即可，这里我主要想唠一唠一些实现过程中的选型。

### SDP vs non SDP

从p4prometheus这个监控项目来看，就有分sdp和nonsdp的安装方式
[perforce/p4prometheus/scripts/docker/Dockerfile](https://github.com/perforce/p4prometheus/tree/master/scripts/docker)

SDP的优势：
明确的文件夹划分，可以让不同的文件夹放到不同性能的存储上。
具体可以参考：

### Docker的细节

#### ubuntu vs centos

centos已经不再官方维护了

#### multi stage

multi stage是会最大化利用本地的缓存的，不用每一次修改，都全量去下载

stage拆分原则，就是每一个下载，都分了一个stage

[Best practices for writing Dockerfiles/Use multi-stage builds](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#use-multi-stage-builds)

#### 打包perforce binaries进入image

有些实现，是在第一次初始化的时候，去下载p4d等二进制的。实测下来，偶尔会遇到下载速度特别慢的情况。为了用户体验，打开image就可以使用p4仓库，就在build image阶段，提前下载好了二进制文件。

如果需要使用不同版本的二进制文件，那么可以使用不同的参数，build一个新的image即可。

## 实现步骤

### Build阶段

#### 1. 下载SDP

#### 2. 下载Perforce二进制文件

### Run阶段

#### 确认SDP是否安装

#### 确认Perforce二进制是否安装

#### 确认SDP Instance是否初始化

#### Run SDP Instance
