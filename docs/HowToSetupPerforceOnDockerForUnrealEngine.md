# 自己动手，在群晖(NAS)上，用Docker搭建Perforce服务器，版本控制Unreal项目

## 需求分析

我的需求是，在自己的NAS(群晖)上，搭建一个Perforce服务器，用来版本控制Unreal项目。

第一步肯定是搜索网上现有的资料，下面是我搜索到的内容：

* [Using Perforce as Source Control](https://docs.unrealengine.com/5.1/en-US/using-perforce-as-source-control-for-unreal-engine/)

Unreal的官方文档，其中重要的关键词是：

"a case-insensitive Perforce server"

"set up your P4 Typemap so Perforce knows how to treat Unreal file types"

* [Setting Up Perforce with Docker for Unreal Engine 4](https://www.froyok.fr/blog/2018-09-setting-up-perforce-with-docker-for-unreal-engine-4/)

跟随上面的case-insensitive, Typemap关键词，搜索到了一篇比较全面的文章，并且在GitHub上面开源了相关代码：([Froyok/froyok-perforce](https://github.com/Froyok/froyok-perforce))

这篇一步一步讲的很详细，如果没有看到下面那篇文章，我很可能会按照这篇文章的方案来搭建。

* [Making a Perforce Server With Docker](https://aricodes.net/posts/perforce-server-with-docker/)

这篇是我和上面同时搜到的文章，这个文章里面的方案我不建议使用，主要是因为作者其实自己平时不使用Perforce：
> I do not personally use Perforce and devised this tutorial for a friend

但是，文章里面却提到了一些比较关键的点：

> It also places files all over the system. You can configure a data directory, but its database is initialized from where the start command is run instead of in a dedicated location and all non-volume files in a Docker container are ephemeral.

作者根据上面的结论，自己写的Dockerfile，分了2个volumes，而前一篇文章的方案，只分配了一个volume。

为了确定到底是一个volume好，还是2个volume好，我还得继续搜索。

* [perforce_software / SDP](https://swarm.workshop.perforce.com/projects/perforce-software-sdp)

加入了volume关键词搜索后，我搜到了官方支持的Server Deployment Package (简称SDP)

> The following describes some of the many features and benefits of using the SDP to manage Helix Core.
>
> Optimal Performance, Data Safety, and Simplified Backup
>
> The SDP provides a standard structure for operating Perforce that is optimized for performance, scalability, and ease of backup. The SDP Guide includes documentation that promotes volume layout and storage architecture best practices.

这个项目主要是通过一些脚本，对P4D Instance进行了一层包装，支持了一台机器多个Instance，甚至每一个Instance都可以有不同版本的P4二进制。

对上一篇文章中吐槽的文件散落在各个位置的问题，SDP也根据文件的性质，进行了目录的合理规划，告诉了你哪个目录要备份，哪个目录要高访问速度等。建议大家可以读一下这个项目的文档（说实话，整个文档还挺长的）。

另外官方默认的文档[Installing the server](https://www.perforce.com/manuals/p4sag/Content/P4SAG/chapter.install.html)里，初始化一个Perforce服务器，并不是用的SDP，可以认为是裸安装(none SDP)的方式。

但是看看官方的p4prometheus这个监控项目来看，分别支持了sdp和nonsdp这两种不同的安装方式安装方式
[perforce/p4prometheus/scripts/docker/Dockerfile](https://github.com/perforce/p4prometheus/tree/master/scripts/docker)

* [Perforce Helix Installer](https://swarm.workshop.perforce.com/projects/perforce_software-helix-installer)

Helix Installer是基于SDP的一个项目，但是这个不是官方支持，是社区支持的项目。
> Please DO NOT contact Perforce Support for the Helix Installer, as it is not an officially supported product offering.

虽然不是官方支持的项目，但是在写Docker中的脚本时，拿项目中的脚本来进行学习和参考还是很有用的。

## 需求总结

看完了上面的各个文档，我的需求已经清晰了：

* 使用SDP
* case-insensitive
* Typemap for Unreal Engine
* Perforce的版本要新
* [Setting up a server for Unicode](https://www.perforce.com/manuals/p4sag/Content/P4SAG/superuser.unicode.setup.html) - 为了仓库更好的支持中文

## 动手实现

### 实现步骤

* Build阶段
  * apt-get安装依赖
  * 下载SDP
  * 下载Perforce二进制文件
* Run阶段
  * 如果SDP未安装，安装SDP
  * 如果Perforce程序文件未安装，安装Perforce程序
  * 如果SDP Instance未初始化，初始化SDP Instance
  * Run SDP Instance

### 源码

源代码在：
[zhaojunmeng/docker-sdp-perforce-server-for-unreal-engine](https://github.com/zhaojunmeng/docker-sdp-perforce-server-for-unreal-engine)

关于源码本身，我添加了比较详细的注释，细节大家可以根据上面提到的实现步骤，看代码即可，这里我主要想唠一唠一些实现过程中的选型。

### Docker的实现细节

#### ubuntu vs centos

找到的代码参考里，base image，既有ubuntu，也有centos。
没选centos的原因是 [This image is no longer supported/maintained](https://hub.docker.com/_/centos)

#### multi stage

multi stage会最大化利用本地的build缓存，避免了修改一行Dockerfile代码，build image时所有文件都要重新下载的问题。

我拆分stage的原则，就是每个不同的下载，都单独作为一个stage存在。参考：

[Best practices for writing Dockerfiles/Use multi-stage builds](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#use-multi-stage-builds)

#### 打包perforce binaries进入image

有些image的实现，是在运行container，执行第一次初始化的时候，去下载p4d等二进制程序文件的。

实测下来，偶尔会遇到p4d下载速度特别慢的情况。为了用户体验，打开image就可以使用P4服务器，我就在build image阶段，提前下载好了二进制文件。

如果你需要使用不同版本的二进制文件，可以自己用不同的参数，build一个新的image即可。

## 实现参考

实现的过程参考了很多前人已经实现好的image，这里列一下，方便大家参考。

下面这些仓库，都不是基于SDP，也都没有unicode的实现，除了第一个基础仓库，其他都实现了case-insensitive和Typemap。

| 链接                                                                                                                     | 描述                                                                                                                                                                                                                                 | 系统   | p4版本 | P4D运行时下载 | DockerImage                                                                                               |
| ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ | ------ | ------------- | --------------------------------------------------------------------------------------------------------- |
| 1. [ambakshi/docker-perforce](https://github.com/ambakshi/docker-perforce)                                               | 目前使用者最多的perforce docker image<br>                                                                                                                                                                                            | centos | 2018.2 | 否            | [ambakshi/perforce-server](https://registry.hub.docker.com/r/ambakshi/perforce-server)                    |
| 2. [Froyok/froyok-perforce](https://github.com/Froyok/froyok-perforce)                                                   | [Setting Up Perforce with Docker for Unreal Engine 4](https://www.froyok.fr/blog/2018-09-setting-up-perforce-with-docker-for-unreal-engine-4/)<br>文章作者在1.基础上增加了case-insensitive和typemap                                  | centos | 2018.2 | 否            | no                                                                                                        |  |
| 3. [MothDoctor/docker-perforce](https://github.com/MothDoctor/docker-perforce)                                           | 作者参考了1.和2.<br>同时还写了一篇在UE下面使用Perforce的经验总结文章: [Using and setting up Perforce repository](https://dev.epicgames.com/community/learning/tutorials/Gxoj/unreal-engine-using-and-setting-up-perforce-repository) | centos | 2022.1 | 否            | [mothdoctor/perforce-server-unreal](https://registry.hub.docker.com/r/mothdoctor/perforce-server-unreal/) |
| 4. [XistGG/docker-perforce-server-for-unreal-engine](https://github.com/XistGG/docker-perforce-server-for-unreal-engine) | 参考了1.和2.                                                                                                                                                                                                                         | ubuntu | latest | 是            | no                                                                                                        |

## 如何运行

参考： [如何在群晖(NAS)上，部署一个为UnrealEngine定制的Perforce服务器](HotToRunPerforceServerOnSynologyForUnrealEngine.md)
