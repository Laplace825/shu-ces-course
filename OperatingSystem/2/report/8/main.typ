#import "../lib/template.typ" : *

#show :base
#set_title(title: "linux文件操作二", author: "", student_id: 114514,  date: "2024.12.27")

= 实验环境

#idnt2 *为防止挂载操作错误破坏系统环境*，实验采用docker容器进行文件系统的挂载与分区。实验环境如@env 所示。

#figure(caption: "实验环境")[
  #table(
    stroke: none,
    inset: 0.5em,
    align: center,
    columns: (20%, 40%),
    table.hline(stroke: 1.2pt),
    [*OS*],
    [_Darwin 24.1.0_],
    table.vline(x: 1),
    [*CPU*],
    [_Apple M3 Arm64_],
    [*Docker*],
    [_Docker 27.4.0_],
    [*Container*],
    [_alpine version: latest_],
    [*Container*],
    [_Red Hat Linux Distro_],
    table.hline(stroke: 1.2pt),
  )
] <env>

= 实验目的

1. 熟悉Linux下的基本操作，使用各种Shell命令操作Linux，对Linux有一个感性认识。
2. 熟悉Linux下文件打包、解压的命令及RPM包的操作。
3. 熟悉Linux下文件系统管理命令，以及加载其他分区的方法。

= 实验内容

== 文件打包、解压(tar, gzip)

=== Docker容器构建

#idnt2 实验采用docker容器构建最小Linux系统`apline`进行文件系统挂载实验。构建`Dockerfile`如@docker.

#code(caption: "Dockerfile")[
```dockerfile
FROM alpine:latest

RUN apk add --no-cache bash util-linux e2fsprogs coreutils

CMD ["bash"]

WORKDIR /app
```
] <docker>

=== tar命令

#set list(indent: 2em)

- 文件不压缩打包，如@tar-cvf。

#code[```bash tar -cvf usr-local.tar /usr/local```]

#img("../assets/tar_cvf.png", width: 350pt, caption: "tar文件不压缩打包") <tar-cvf>

- 文件解包，如@tar-xvf。

#code[```bash tar -xvf usr-local.tar```]

#img("../assets/tar_xvf.png", width: 350pt, caption: "tar文件解包") <tar-xvf>

- 文件包测试，如@tar-tf。

#code[```bash tar -tf usr-local.tar```]

#img("../assets/tar_tf.png", width: 350pt, caption: "tar文件包测试") <tar-tf>

- 文件压缩打包，如@tar-zcvf。可以看见，压缩后的包大小仅160B而不压缩的包为10KB。

#code[```bash tar -zcvf usr-local-zcvf.tar.gz /usr/local```]

#img("../assets/tar_zcvf.png", width: 350pt, caption: "tar文件压缩打包") <tar-zcvf>

- 文件解压缩，如@tar-zxvf。可以看见，解压后多出了一个`usr`目录。

#code[```bash tar -zxvf usr-local-zcvf.tar.gz```]

#img("../assets/tar_zxvf.png", width: 350pt, caption: "tar文件解压缩") <tar-zxvf>

- 文件压缩包测试，如@tar-ztf。

#code[```bash tar -ztf usr-local-zcvf.tar.gz```]

#img("../assets/tar_ztf.png", width: 350pt, caption: "tar文件压缩包测试") <tar-ztf>

=== gzip命令

- 将当前目录下的每个文件压缩成.gz文件，如@gzip-all-file。

#code[```bash gzip *```]

#img("../assets/gzip_all_file.png", width: 350pt, caption: "gzip所有文件") <gzip-all-file>

- 将当前目录下的每个压缩的文件解压，并列出详细信息，如@gzip-dv。

#code[```bash gzip -dv *```]

#img("../assets/gzip_dv.png", width: 350pt, caption: "gzip解压文件") <gzip-dv>

- 详细当前目录下的压缩文件的信息，但不进行解压，如@gzip-l。

#code[```bash gzip -l *```]

#img("../assets/gzip_l.png", width: 350pt, caption: "gzip文件信息") <gzip-l>

- 递归的压缩目录，如@gzip-rv。可以看见压缩后`tmp`文件内的文件都被压缩成了.gz格式，包括`inner/src/code.txt`。

#code[```bash gzip -rv tmp```]

#img("../assets/gzip_rv.png", width: 350pt, caption: "gzip递归压缩目录") <gzip-rv>

- 递归的解压目录，如@gzip-drv。

#code[```bash gzip -drv tmp```]

#img("../assets/gzip_drv.png", width: 350pt, caption: "gzip递归解压目录") <gzip-drv>

== RPM包操作

=== Red Hat Linux 镜像

#idnt2 使用docker拉取Red Hat Linux系统。

#code[```bash docker pull redhat/ubi8```]

=== 构建最小RPM包

#idnt2 由`spec`文件构建RPM包需要遵循RPM包的构建语法。#link("https://rpm-software-management.github.io/rpm/manual/spec.html")[RPM Manual Spec-Syntax]。

#idnt2 本次实验仅尝试构建最小RPM包`hello-world`，`hello-world.spec`如@hello-world。

#code(caption: "hello-world.spec")[```r
Name:       hello-world
Version:    1
Release:    1
Summary:    Most simple RPM package
License:    FIXME

%description
This is my first RPM package, which does nothing.

%prep
# we have no source, so nothing here

%build
cat > hello-world.sh <<EOF
#!/usr/bin/bash
echo Hello world
EOF

%install
mkdir -p %{buildroot}/usr/bin/
install -m 755 hello-world.sh %{buildroot}/usr/bin/hello-world.sh

%files
/usr/bin/hello-world.sh

%changelog
# let's skip this for now
```] <hello-world>

#idnt2 根据当前文件创建`rpm`包，如@rpmbuild，该包将被创建在```bash ${HOME}/rpmbuild/RPMS/aarch64```目录下(路径最后的`aarch64`表示使用的cpu架构，对于一般的`x86_64`机器，该路径为`x86_64`)。

#code[```bash rpmbuild -ba hello-world.spec```]

#img("../assets/rpmbuild.png", caption: "rpmbuild", width: 350pt) <rpmbuild>

=== 安装RPM包

#idnt2 安装`hello-world`包，如@rpm-i。安装后查找`hello-world.sh`路径，可以发现在`/usr/bin`目录下。且可以直接运行`hello-world.sh`。

#code[```bash rpm -i ${HOME}/rpmbuild/RPMS/aarch64/hello-world-1-1.aarch64.rpm```]

#img("../assets/rpm-i.png", width: 350pt, caption: "rpm安装") <rpm-i>

== 文件系统挂载

=== 创建文件系统

#idnt2 使用`dd`命令在本地主机创建一个大小为`1GB`的文件`disk.img`，如@dd。

#code[```bash dd if=/dev/zero of=disk.img bs=1M count=1024```]

#img("../assets/dd_disk.png", width: 350pt, caption: "dd创建1GB文件") <dd>

=== 新建alpine容器并挂载disk

#idnt2 使用`alpine`容器新建一个容器，并赋予容器使用`disk.img`的权限，并复制在容器根目录下。如@docker-disk-in。

#code[```bash  docker run --rm -it --privileged -v $(pwd)/disk.img:/disk.img file_op2:latest bash```]

#img("../assets/docker_disk_in.png", width: 350pt, caption: "docker挂载disk.img") <docker-disk-in>

=== 将disk.img设置为循环设备

#idnt2 循环设备可把文件虚拟成区块设备，籍以模拟整个文件系统，让用户得以将其视为硬盘驱动器，光驱或软驱等设备，并挂入当作目录来使用。如@docker-disk-losetup。

#img("../assets/docker_disk_losetup.png", width: 350pt, caption: "docker设置disk.img为循环设备") <docker-disk-losetup>

=== 将循环设备进行分区

#idnt2 所有的循环设备文件路径为`/dev/loop*`，我们选择`/dev/loop0`进行分区。如@docker-disk-fdisk-p。分区后多的区块设备文件路径为`/dev/loop0p1`。可以看到该分区为`1023MB`。

#img("../assets/docker_disk_fdisk-p.png", width: 350pt, caption: "docker分区") <docker-disk-fdisk-p>

#idnt2 如@docker-disk-ls-dev，我们可以在重启容器后查看到`/dev/loop0p1`分区已经被成功创建。

#img("../assets/docker_disk_ls-dev.png", width: 350pt, caption: "docker查看循环设备") <docker-disk-ls-dev>

=== 格式化分区为ext4文件系统

#idnt2 我们将`/dev/loop0p1`分区格式化为`ext4`文件系统，如@docker-disk-mkfs。

#img("../assets/docker_disk_part_mkfs_ext4.png", width: 350pt, caption: "docker格式化分区为ext4") <docker-disk-mkfs>

=== 挂载ext4文件系统

#idnt2 我们将`/dev/loop0`挂载到`/mnt/disk`目录，如@docker-disk-mount，使用`df -h`查看挂载情况。可以看见`/dev/loop0`分区已经挂载到`/mnt/disk`目录。

#img("../assets/docker_disk.png", width: 350pt, caption: "docker挂载块设备") <docker-disk-mount>

#idnt2 用同样的方法，我们将`/dev/loop0p1`分区挂载到`/mnt/disk`目录，并在该目录下新建文件`test.txt`，查看该路径，可以发现多了一个`lost+found/`目录，并且能正常读写`test.txt`文件。如@docker-disk-part-mount。

#img("../assets/docker_disk_mount.png", width: 350pt, caption: "docker挂载分区") <docker-disk-part-mount>

=== 卸载分区

#idnt2 我们卸载`/mnt/disk`目录下的`/dev/loop0p1`分区，如@docker-disk-umount。可以看见卸载后`/mnt/disk`目录下的`test.txt`文件无法读取。

#img("../assets/docker_disk_umount.png", width: 350pt, caption: "docker卸载分区") <docker-disk-umount>

== 文件系统维护命令

=== du 命令

#idnt2 `du`命令用于显示文件或目录所占用的磁盘空间。如@du。可以查看到`/usr`目录下的文件大小。

#img("../assets/du_usr.png", width: 350pt, caption: "du命令") <du>

=== df 命令

#idnt2 `df`命令用于显示磁盘分区上的可用磁盘空间。如@df。添加`-H`参数可以以更加人类可读的情况查看磁盘空间。

#img("../assets/df-H-a.png", width: 350pt, caption: "df命令") <df>

=== fsck 命令

#idnt2 `fsck`命令用于检查和修复Linux文件系统。如@fsck。可以看见`/dev/loop0p1`分区没有错误。

#img("../assets/fsck.png", width: 350pt, caption: "fsck命令") <fsck>

=== free 命令

#idnt2 `free`命令用于显示系统内存的使用情况。如@free。添加`-h`参数可以以更加人类可读的情况查户口系统内存的使用情况。

#img("../assets/free-h.png", width: 350pt, caption: "free命令") <free>

= 思考题

== tar与gzip有何区别、联系？

*答：*

*区别*：`tar`是打包命令，`gzip`是压缩命令。`tar`打包后的文件大小不变，`gzip`压缩后的文件大小变小。`tar`一次性将多个文件打包成一个文件，`gzip`一次性只对单个文件进行压缩。`tar`打包后的文件名添加`.tar`后缀，`gzip`压缩后的文件名会添加`.gz`后缀。

*联系*：`tar`打包并要求压缩时会调用`gzip`进行压缩，最终得到的包名添加的后缀为`.tar.gz`表示打包并压缩。`tar`解压缩包时会调用`gzip`进行解压缩。

= 体会

#idnt2 本次实验主要学习了Linux下的文件操作命令，包括文件打包、解压、RPM包操作、文件系统挂载等。通过实验，我对Linux下的文件操作有了更深入的了解，对Linux系统有了更加感性的认识。同时，通过实验，我学会了如何使用`tar`、`gzip`等命令对文件进行打包、解压缩，以及如何使用`RPM`包进行安装，如何使用`dd`命令创建文件系统，如何使用`fsck`命令检查文件系统等。这些命令在Linux系统中是非常常用的，对于Linux系统的管理和维护有着重要的作用。
