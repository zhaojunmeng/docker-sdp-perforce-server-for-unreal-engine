# 如何在群晖(NAS)上，部署一个为UnrealEngine定制的Perforce服务器

## 安装Docker

如果你的群晖没有安装Docker，首先需要在群晖的“套件中心”里面搜索Docker，并安装。

(安装Docker的方法就不在这里讲解了，可以自行搜索)

## 下载Docker image

1. 打开“Docker”应用，点击左侧的“映像”Tab，再点击“新增”-“从URL添加”

    ![1](images/SynologyAddImage_1.png)

2. 在弹出的“从 URL 添加”界面中，在“地址”部分，粘贴下面的地址，然后“新增”按钮

    <https://hub.docker.com/r/zhaojunmeng/sdp-perforce-server-for-unreal-engine>

    ![2](images/SynologyAddImage_2.png)

## 启动容器

1. 在“映像”Tab，找到刚刚下载的Image，点击“启动”

    ![1](images/RunningOnSynology_1.png)

2. 网络/常规设置界面，使用默认配置即可

    ![2](images/RunningOnSynology_2.png)

    ![3](images/RunningOnSynology_3.png)

3. 端口界面，填写你要映射的端口号。

    (P4默认的端口号习惯是1666)

    ![4](images/RunningOnSynology_4.png)

4. 存储空间设置界面，要点击“添加文件夹”

    ![5](images/RunningOnSynology_5.png)

    右边红圈里，/hxdepots, /hxlogs, /hxmetadata, /p4这4个目录是一定要提供的。(这4个目录的含义，以及建议对应的存储方式，参考: [Volume Layout and Hardware](https://swarm.workshop.perforce.com/projects/perforce-software-sdp/view/main/doc/SDP_Guide.Unix.html#_volume_layout_and_hardware))

    左边红圈是在NAS里面的文件夹，是Docker启动以后，Perforce的数据文件等持久化的地方。

    ![6](images/RunningOnSynology_6.png)

5. 点击完成，然后确认容器启动成功

    ![7](images/RunningOnSynology_7.png)

    ![8](images/RunningOnSynology_8.png)

## 连接到Perforce服务器

容器启动以后，需要首先使用[P4Admin](https://www.perforce.com/downloads/administration-tool)工具，登录Perforce服务器，才能创建新的depot，group和user。

>Server: 服务器的ip地址或者域名，外加之前启动容器步骤时设置的端口号，比如：1666
>
>User: 填写"perforce"

![1](images/P4Admin_1.png)

点击“OK”后，会弹出修改密码界面。(security level 3会要求第一次登陆时，必须修改密码)

输入old password: F@stSCM!，然后输入新密码，点击“OK”

![2](images/P4Admin_2.png)

登录成功后，就可以开始创建depot，group和user了。

Enjoy!

## 如何实现

如何实现参考：[自己动手，在群晖(NAS)上，用Docker搭建Perforce服务器，版本控制Unreal项目](HowToSetupPerforceOnDockerForUnrealEngine.md)
