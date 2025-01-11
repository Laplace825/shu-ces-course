#import "../lib/template.typ" : *

#show: base

#set_title[Spark-SQL分布式数据库部署]

= `Spark-SQL`数据库部署

== 安装`JAVA`

#idnt2 安装`JAVA`并配置环境变量。`java -version`查看版本。

#figure(image("../assets/java_version.png", width: 400pt, height: 80pt), caption: "Java Version")

== 安装`Hadoop`

#idnt2 安装`Hadoop`并配置环境变量。`hadoop version`查看版本。

#figure(image("../assets/slave_jps.png", width: 400pt, height: 80pt), caption: "Hadoop Version")

== JPS

#idnt2 启用`Hadoop`后，使用`jps`查看进程。

#figure(image("../assets/master_jps.png", width: 400pt, height: 80pt), caption: "JPS")

== 启用`Spark`数据库并读入`json`数据

#idnt2 先启用`hdfs`，再启用`spark`。

#figure(image("../assets/spark_people_json_table.png", width: 400pt, height: 80pt), caption: "Start Spark")

= 查询

== 按洲和年份分组查询，出生婴儿的男女比例。

#idnt2 输出格式：(State, Year, MRatio, FRatio)

#figure(image("../assets/spark_query1.png", width: 400pt, height: 200pt), caption: "Query 1")

== 按年份分组查询，查询母亲受教育程度与平均生育年龄的关系。
#idnt2 输出格式： (Year, Education_Level_Code, Average_Age_of_Mother)

#figure(image("../assets/spark_query2.png", width: 400pt, height: 200pt), caption: "Query 2")

== 按年份分组查询，查询平均生育年龄与婴儿平均体重的关系。

#idnt2 输出格式： (Year, Average_Age_of_Mother, Average_Birth_Weight)

#figure(image("../assets/spark_query3.png", width: 400pt, height: 100pt), caption: "Query 3")