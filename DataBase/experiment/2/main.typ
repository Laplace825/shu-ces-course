#import "../lib/template.typ": *

#show: base

#set_title(title: "实验二SQL基本操作", name: "xxx", student_id: "xxxx")

= 按要求建表并插入数据

#idnt2 在`MySQL`中创建`project`数据库，并在该数据库中创建`S, P, J, SPJ`三张表。各表数据见右图, 以下是`S`表的建表语句：

#grid(
  columns: (1fr, 1fr),
  inset: 2pt,
  align(left)[#figure(image("../assets/table_S.png", width: 17em), caption: "S table")],
  align(right)[#figure(image("../assets/table_P.png", width: 17em), caption: "P table")],

  align(right)[#figure(image("../assets/table_J.png", width: 17em), caption: "J table")],
  align(right)[#figure(image("../assets/table_SPJ.png", width: 17em, height: 125pt), caption: "SPJ table")],
)

= 单表查询与多表查询

== 检索供应零件编号为 J1 的工程的供应商编号 SNO

#code_img(path: "../assets/2_q1.png", caption: "Query Result for 2.1")[
  ```sql
  SELECT SNO,JNO
  FROM SPJ
  WHERE JNO='J1';
  ```
]

== 检索供应零件给工程J1，且零件编号为 P1 的供应商编号SNO

#code_img(path: "./assets/2_q2.png", caption: "Query Result for 2.2")[
  ```sql
  SELECT SNO
  FROM SPJ
  WHERE JNO='J1' AND PNO='P1';
  ```
]

== 查询没有正余额的工程编号、名称及城市，结果按工程编号升序排列

#code_img(path: "../assets/2_q3.png", caption: "Query Result for 2.3")[
  ```sql
  SELECT JNO,JNAME,JCITY
  FROM J WHERE Balance<=0 ORDER BY JNO;
  ```
]

== 求使用零件数量为100到1000的工程编号、零件号和数量

#code_img(path: "../assets/2_q4.png", caption: "Query Result for 2.4")[
  ```sql
  SELECT JNO,PNO,QTY
  FROM SPJ WHERE
  QTY>=100 AND QTY<=1000;
  ```
]

== 查询上海的供应商名称，假设供应商关系SADDR列的值都以城市名开头

#code_img(path: "../assets/2_q5.png", caption: "Query Result for 2.5")[
  ```sql
  SELECT SNAME
  FROM S
  WHERE SADDR
  LIKE "Shanghai%";
  ```
]

== 检索使用了P3零件的工程名称

#code_img(path: "../assets/2_q6.png", caption: "Query Result for 2.6")[
  ```sql
  SELECT J.JNAME
  FROM SPJ JOIN J
  ON SPJ.JNO=J.JNO
  WHERE SPJ.PNO='P3';
  ```
]

== 检索供应零件给工程J1，且零件颜色为红色的供应商编号SNO

#code_img(path: "../assets/2_q7.png", caption: "Query Result for 2.7")[
  ```sql
  SELECT S.SNO
  JOIN P ON SPJ.PNO=P.PNO
  JOIN S ON S.SNO=SPJ.SNO
  WHERE COLOR='red' AND JNO='J1';
  ```
]

== 检索至少使用了零件编号为P3和P5的工程编号JNO

#code_img(path: "../assets/2_q8.png", caption: "Query Result for 2.8")[
  ```sql
  SELECT JNO FROM SPJ
  WHERE PNO IN ('P3','P5')
  GROUP BY JNO
  HAVING COUNT(DISTINCT PNO)>=2;
  ```
]

== 检索不使用编号为P3零件的工程编号JNO和名称JNAME

#code_img(path: "../assets/2_q9.png", caption: "Query Result for 2.9")[
  ```sql
  SELECT J.JNO,J.JNAME FROM J
  WHERE J.JNO NOT IN (
    SELECT JNO FROM SPJ
    WHERE PNO='P3');
  ```
]