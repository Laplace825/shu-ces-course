#set text(font: ("Times New Roman", "Songti SC"), size: 12pt, lang: "zh", region: "cn")
#set heading(bookmarked: true, numbering: "1.")
#set par(first-line-indent: 2em, justify: true, spacing: 1.25em)
#set page(
  "a4",
  header-ascent: 2em,
  header: align(right)[
    _DataBase Principle (1) Experiment_
  ],
  numbering: "1/1",
)
#show heading.where(level: 1): set text(size: 14pt, weight: "bold")
#show heading.where(level: 2): set text(size: 12pt, weight: "bold")
#show heading.where(level: 3): set text(size: 12pt)

#align(
  center,
  text(18pt, font: ("Times New Roman", "Heiti SC"))[
    *实验一MySQL数据库的C/S模式部署*
  ],
)

#align(center)[#line(length: 60%)]

#grid(
  columns: (1.3fr, 1fr),
  align(
    center,
    text(13pt)[
      *学号:* \
      *姓名:* \
    ],
  ),
  align(
    left,
    text(13pt)[
      xxx \
      xxxx
    ],
  ),
)
#align(center)[#line(length: 60%)]

#let idnt2 = h(2em)

= 租借两台腾讯云服务器
#idnt2 先后在腾讯云中租借两云服务器，并放开相应的安全组规则，例如22、3306、443、80等端口，通过SSH远程登录服务器。

// This is commented out because the image may contains some sensitive information.(image is removed in the repo)
// #figure(image("../assets/tencent_yun.png", height: 35%), caption: "腾讯云服务器租借")

= ssh免密登录
#idnt2 为两台主机先后生成rsa密钥对，将公钥添加到`authorized_keys`文件中，并直接将私钥和公钥文件拷贝到另一台主机，实现免密登录。

== 生成密钥对
#idnt2 在主机上使用`ssh-keygen`命令生成密钥对.

#align(center)[#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 0.5em, radius: 4pt)[```bash
    ssh-keygen -t rsa -C "xxx@email.com"
    ```]]

#figure(image("../assets/ssh_keygen.png", height: 35%), caption: "生成密钥对")

== 密钥共享后尝试无密码连接
#idnt2 将密钥对通过`scp`共享。

#align(center)[#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 0.5em, radius: 4pt)[```bash
    scp ~/.ssh/id_rsa.pub ubuntu@xx.xx.xx.xx:~/.ssh/id_rsa.pub
    scp ~/.ssh/id_rsa ubuntu@xx.xx.xx.xx:~/.ssh/id_rsa
    ```]]

#idnt2 尝试无密码连接。

#figure(image("../assets/ssh_connect.png", height: 35%), caption: "无密码连接")

= 配置MySQL环境

== 初始化环境
#idnt2 在两台主机上安装MySQL Server，在server主机上创建一个数据库`laplace`，一个用户`client`，并授权给该用户。

#align(center)[#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 0.5em, radius: 4pt)[```sql
    CREATE DATABASE laplace;
    CREATE USER 'client'@'10.206.0.3' IDENTIFIED BY '114514';
    GRANT ALL PRIVILEGES ON *.* TO 'client'@'10.206.0.3';
    FLUSH PRIVILEGES;
    EXIT;
    ```]]

== 使用client主机连接server主机MySQL服务
#idnt2 在client主机上使用`mysql`命令连接server主机的MySQL服务。

#align(center)[#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 0.5em, radius: 4pt)[```bash
    mysql -h 10.206.0.13 -u client -p
    ```]]

#figure(image("../assets/client_connect_mysql.png", height: 35%), caption: "连接MySQL服务")
