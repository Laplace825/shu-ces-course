#import "lib.typ" as lib
#show: lib.lib-style

#set page(
  "a4",
  header-ascent: 2em,
  header: align(right)[#text(size: 8pt)[
      _DataBase Principle (1) Experiment_
    ]],
  numbering: "1/1",
)

#let set_title(title) = {
  align(
    center,
    text(16pt, font: ("Times New Roman", "Heiti SC"))[
      *#title*
    ],
  )

  align(center)[#line(length: 60%)]

  grid(
    rows: 2,
    row-gutter: 1em,
    columns: (1fr, 1fr),
    column-gutter: -20em, // Reduced from default to bring columns closer
    align: center,
    [瓜], [你劈我瓜],
    [(19191818)], [(114514)],
  )

  align(center)[#line(length: 60%)]
}

#set_title([数据库推荐系统])

#set par(first-line-indent: (amount: 2em, all: true))


= Jaccard 相似度度量 <sec:jaacard>

数据集包括两列, 数值代表一个用户的哈希ID, 第一列代表用户 $x_i$,
第二列代表用户 $x_j$, 两列数据代表 $x_i -> x_j$ 存在有向边.
对于两个用户之间的相似度度量, 定义 $A$ 代表用户 $x_i$ 的出度集合,
$B$ 代表用户 $x_j$ 的出度集合, 则 $A inter B$ 代表两个用户共同关注的用户集合,
$A union B$ 代表两个用户关注的所有用户集合, 则 Jaccard 相似度度量定义如@eq:jaccard .

$
  "jaccard"(A, B) = (||A inter B||) / (||A union B||)
$ <eq:jaccard>

实际上, 数据集为有向图, 对于每个用户的出度, 只需要为第一列数据分组, 组内统计第二列共多少不重复列即可得到所有用户的出度.

基于基数等式@eq:union-intersection , 可以将 Jaccard 相似度度量中较难获得的并集部分转化为两个集合的元素总数与交集的差.

$
  ||A inter B|| + ||A union B|| = ||A|| + ||B||
$ <eq:union-intersection>

= Spark-SQL 分布式查询

== 单机

=== 连接查询

针对@sec:jaacard , 可以将计算分为两个部分, 第一部分为计算用户的出度, 第二部分为计算用户之间的共同关注用户集合(即交集). 最后根据前两张表计算获取 jaacard 相似度. 具体代码参考@appendix-sec:join .

#lib.graph(caption: "单机连接语句运行时间", path: "1-slave-wjh-join-156s.png")

=== 嵌套查询

可以将连接查询中关于 $||A inter B||$ 和最终结果计算的两张表进行嵌套, 再组合成结果表.
具体代码参考@appendix-sec:nest . 然而我们发现, 这个嵌套语句的执行时间要比之前的连接查询更多.
猜测是因为嵌套本身依然使用了连接去得到最终结果, 然而实际上由于缓存机制, Spark-SQL 可以将之前需要重复查询的表缓存起来, 这导致在嵌套查询中计算 $||A inter B||$ 的部分可能难以直接缓存, 从而导致了嵌套查询的执行时间更长.

#lib.graph(caption: "单机嵌套语句运行时间", path: "1-node-nested-167s.png")

== 多机

为了将两台 slave 机器一起参与到计算过程中, 经过查询, 我们需要为 Spark 添加环境变量配置项, 保证 Spark 能够找到 Hadoop 配置.

#lib.code(caption: [Spark添加环境变量配置])[
  ```bash
  # in spark-env.sh
  ...
  export HADDOP_HOME="/usr/local/hadoop"
  export HADDOP_CONF_DIR="${HADDOP_HOME}/etc/hadoop"
  ...
  ```
]

再重新启动 Hadoop 之后, 可以通过 `--master yarn` 选项让 `spark-sql` 调用集群算力.
为保证 master 机器不会因为参与计算导致卡顿, 我们只让两个 slave 机器进行计算, 如@code:spark-cluster .

#lib.code(caption: [Spark调用集群算力])[
  ```bash
  spark-sql --master yarn
            --num-executors 2
            --executor-cores 2
            --executor-memory 2g
  ```
] <code:spark-cluster>

=== 连接查询

调用同样的连接查询语句, 可以得到结果为 131s . 并没有得到约两倍的速度提升, 这可能是因为连接查询本身并不是一个可以并行化的操作, 无法充分利用多机的计算资源.

#lib.graph(path: "2-slave-wjh-join-131s.png", caption: "多机连接语句运行时间")


=== 嵌套查询

进行了无数次尝试, 包括开更大内存的机器后, 我们依然遇到多机情况下出现 `Java Out of Memory` 的情况, 无法得到查询的结果. 我们同样尝试了将重分区数降低, 降低 Spark-SQL 多机可用内存或提高 Spark-SQL 多机可用内存, 然而均出现了内存泄露的情况, 由于我们两个都不是 Java 语言选手,
这个问题没得到解决. 即使看报错信息, 发现也只是提示可以打开对于内存泄露的 reporting, 十分遗憾.

`ERROR util.ResourceLeakDetector: LEAK: ByteBuf.release() was not called before it's garbage-collected. Enable advanced leak reporting to find out where the leak occurred. To enable advanced leak reporting, specify the JVM option '-Dio.netty.leakDetection.level=advanced' or call ResourceLeakDetector.setLevel() See http://netty.io/wiki/reference-counted-objects.html for more information.

java.lang.OutOfMemoryError: Java heap space`

= 结果

我们的运行结果见@img:result . 可以看到, 单机情况下, 连接查询和嵌套查询的运行时间分别为 156s 和 167s . 多机情况下, 连接查询的运行时间为 131s . 由于嵌套查询无法得到结果, 我们无法得知多机情况下嵌套查询的运行时间.

#lib.graph(path: "final-time.svg", caption: "运行时间结果", width: 100%) <img:result>

#show: lib.appendix-show

= SQL单机查询

== 连接 <appendix-sec:join>

#lib.code(caption: "连接查询")[
  ```sql
    WITH
      DEG AS (
          SELECT a AS p, count(distinct b) AS p_out_cnt
          FROM R GROUP BY a
      ),
      common AS (
          SELECT
              r1.a AS s,
              r2.a AS t,
              count(*) AS com_cnt
          FROM R r1 JOIN R r2 ON r1.b = r2.b AND r1.a < r2.a
          GROUP BY r1.a, r2.a
      )
  SELECT
      common.s AS s,
      common.t AS t,
      CASE
          when d1.p_out_cnt + d2.p_out_cnt - common.com_cnt > 0
          THEN common.com_cnt / (d1.p_out_cnt + d2.p_out_cnt - common.com_cnt)
          ELSE 0
      END AS similarity
  FROM
      DEG d1 JOIN
      DEG d2 JOIN
      common ON d1.p = common.s AND d2.p = common.t
  ORDER BY
      similarity DESC;
  ```
]

== 嵌套 <appendix-sec:nest>

#lib.code(caption: "嵌套查询")[
  ```sql
  WITH
      ds AS (
          -- Calculate degrees for source
          SELECT a AS p, COUNT(DISTINCT b) AS p_out_cnt
          FROM R GROUP BY a
      )
  SELECT
      ab.s, ab.t,
      (
        CAST(ab.com_cnt AS FLOAT) / (ds.p_out_cnt + dt.p_out_cnt - ab.com_cnt)
      ) AS jaccard
  FROM
      (
          -- Calculate intersection (A ^ B)
          SELECT
              r1.a AS s,
              r2.a AS t,
              COUNT(*) AS com_cnt
          FROM
              R r1 JOIN R r2 ON r1.b = r2.b AND r1.a < r2.a
          GROUP BY r1.a, r2.a
      ) ab JOIN ds ON ad.s = ds.p
      JOIN (
          -- Calculate degrees for target
          SELECT
              a AS p,
              COUNT(DISTINCT b) AS p_out_cnt
          FROM R GROUP BY a
      ) dt ON ab.t = dt.p;
  ```
]

