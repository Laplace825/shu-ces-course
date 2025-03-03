#import "../lib/template.typ": *

#show: base

#set_title([Spark-SQL分布式数据库查询-推荐系统])

= 预先构建的表

== 原始表

根据原始数据集构建表 `R(a INT, b INT)`.

== 中间表

对于嵌套查询以及存在量词等方法, 暂时没有想到完全不使用`JOIN`操作的方法, 所以将部分共用的表预先创建. `DEG` 代表点的出度, `A_AND`代表交集.

#code[```sql
  CREATE TABLE IF NOT EXISTs DEG AS (
      -- |A|
      SELECT
          a AS p,
          COUNT(DISTINCT b) AS p_out_cnt
      FROM
          R
      GROUP BY
          a
  );
  CREATE TABLE IF NOT EXISTS A_AND AS (
      -- |A ^ B|
      SELECT
          r1.a AS s,
          r2.a AS t,
          COUNT(*) AS com_cnt
      FROM
          R r1
          JOIN R r2 ON r1.b = r2.b
          AND r1.a < r2.a
      GROUP BY
          r1.a,
          r2.a
  );
  ```]

= 连接查询

实际上连接查询不需要用到 `MAPPED` 表, 但是为了方便后续的 `Jaccard` 计算同时保证连接操作更多的信息, 我在这里使用了 `MAPPED` 表.
这里我也限制只输出3000行, *在之后的代码中统一只输出3000行.*

#code[
  ```sql
  WITH
      MAPPED AS (
          SELECT
              deg_l.p AS s,
              deg_r.p AS t,
              deg_l.p_out_cnt AS p_out_cnt_s,
              deg_r.p_out_cnt AS p_out_cnt_t
          FROM
              DEG deg_l
              JOIN DEG deg_r ON deg_l.p != deg_r.p
      )
  SELECT
      A_AND.s,
      A_AND.t,
      A_AND.com_cnt AS com_cnt,
      (
          CAST(A_AND.com_cnt AS FLOAT) / (MAPPED.p_out_cnt_s + MAPPED.p_out_cnt_t - com_cnt)
      ) AS jaccard
  FROM
      MAPPED
      JOIN A_AND ON MAPPED.s = A_AND.s
      AND MAPPED.t = A_AND.t
  LIMIT
      3000;
  ```
]

= 相关子查询

将计算并集的部分作为子表嵌入到 `SELECT` 语句中, 同时该表的查询条件依赖外部的 `A_AND` 表.

#code[
  ```sql
  SELECT
      A_AND.s,
      A_AND.t,
      (
          CAST(A_AND.com_cnt AS FLOAT) / (
              (
                  SELECT
                      MAX(p_out_cnt)
                  FROM
                      DEG
                  WHERE
                      p = A_AND.s
              ) + (
                  SELECT
                      MAX(p_out_cnt)
                  FROM
                      DEG
                  WHERE
                      p = A_AND.t
              ) - A_AND.com_cnt
          )
      ) AS jaccard
  FROM
      A_AND
  LIMIT
      3000;
  ```
]

= 存在量词

检索`DEG`连接后存在`p`与`A_AND`相同的`s`和`t`且两个`DEG`的`p`不相同的记录作为过滤出的行, 之后再连接`DEG`表计算结果.

#code[
  ```sql
  SELECT
      s,
      t,
      (
          CAST(com_cnt AS FLOAT) / (
              deg_s.p_out_cnt + deg_t.p_out_cnt - com_cnt
          )
      ) AS jaccard
  FROM
      (
          SELECT *
          FROM A_AND
          WHERE EXISTS (
              SELECT 1
              FROM DEG deg_l, DEG deg_r
              WHERE deg_l.p != deg_r.p
              AND deg_l.p = A_AND.s
              AND deg_r.p = A_AND.t
          )
      ) filtered
      JOIN DEG deg_s ON filtered.s = deg_s.p
      JOIN DEG deg_t ON filtered.t = deg_t.p
  LIMIT 3000;

  ```
]

= 集合

在 Spark-SQL 上一直有语法问题, 但是可以在本地的 sqlite 中跑通, 这里并没想出来该如何进行修改, 所以暂时没有在 Spark-SQL 上实现. 本地的 sqlite 运行时间为 42.382s.

在原始表R上, 通过 `UNION` 和 `INTERSECT` 操作, 分别得到两个集合, 之后通过 `COUNT` 函数计算交集大小和并集大小.

#code[
  ```sql
  SELECT
      r1.a AS node1,
      r2.a AS node2,
      -- 交集大小 |A ∩ B|
      CAST(
          (
              SELECT
                  COUNT(*) FROM (
                      SELECT DISTINCT b FROM R WHERE a = r1.a
                      INTERSECT
                      SELECT DISTINCT b FROM R WHERE a = r2.a
                  )
          ) AS FLOAT
      ) / (
          SELECT
              COUNT(*)
          FROM
              (
                  SELECT DISTINCT b FROM R WHERE a = r1.a
                  UNION
                  SELECT DISTINCT b FROM R WHERE a = r2.a
              )
      )
  FROM
      R r1 JOIN R r2 ON r1.a < r2.a
  LIMIT
      3000;
  ```
]

= 结果

由于集合查询并没有在 Spark-SQL 上跑通, @img:res 只展示了跑通的语句时间, 从上到下依次为存在量词、相关子查询、连接. 对于集合查询语句, 在Apple M3本地 sqlite 上用时为 42.382s.

#figure(image("../assets/ex4-time.svg", width: 100%), caption: "Spark跑通的运行时间") <img:res>
