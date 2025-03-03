#import "lib.typ" as lib

#show: lib.lib-style

#let title = "数据降维与可视化方法"
#let id = 114514
#let name = "laplace"

#set page(
  header: align(left)[
    #image("./logo_shu.svg", width: 20%)
  ],
)

#lib.make-cover(title: title, id: id, name: name)

#set page(
  header: align(right)[
    #move(dy: 1em)[
    #image("./logo_shu.svg", width: 15%)]
  ],
)

#lib.make-title(title, id: id, name: name)

#lib.make-abstract([本文聚焦于UMAP与t-SNE算法,
  深入探讨在高维数据降维与可视化中的原理、实现细节及优缺点.
  UMAP作为一种新兴的非线性降维方法, 通过构建高维数据的拓扑结构并优化低维嵌入,
  能够在保留数据局部和全局结构的同时显著提升计算效率. 本文详细叙述了UMAP和t-SNE的核心步骤,
  并通过实验验证了UMAP和t-SNE的相关优势与不足.
  实验结果表明, UMAP在降维效果和计算效率上优于t-SNE.
])[数据降维,][可视化,][UMAP,][t-SNE,][非线性降维]

#set par(first-line-indent: (amount: 2em, all: true))



= 背景

随着大数据时代的到来, 高维数据的获取和处理变得日益普遍. 然而, 高维数据的分析和可视化面临诸多挑战,
其中最显著的问题是"维数灾难"(Curse of Dimensionality)#cite(<bellman2003dynamic>) .
随着数据维度的增加, 数据点在空间中的分布变得极其稀疏, 导致传统的数据分析方法失效.
例如, 在高维空间中, 数据点之间的距离趋于相似, 这使得基于距离的聚类、分类和可视化方法难以有效区分数据的内在结构.
从@img:1d 到@img:3d_10000 , 我们展示了不同数量级的点在单位长度空间中的均匀分布情况, 可以发现,
随着数据维度的增加, 数据点之间的距离变得越来越远, 数据分布变得越来越稀疏.

#grid(columns: 2)[
  #lib.graph(path: "../gen_1d.png", caption: "100个点一维均匀分布", width: 80%) <img:1d>
][
  #lib.graph(path: "../gen_2d_100.png", caption: "100个点二维均匀分布", width: 80%) <img:2d>
][
  #lib.graph(path: "../gen_2d_10000.png", caption: "10000个点二维均匀分布", width: 80%) <img:2d_10000>
][
  #lib.graph(path: "../gen_3d_10000.png", caption: "10000个点三维均匀分布", width: 80%) <img:3d_10000>
]

此外, 高维数据的可视化本身也是一个巨大的挑战. 人类视觉系统只能直观理解三维及以下的数据, 而高维数据无法直接映射到二维或三维空间进行展示.
这不仅限制了数据的直观理解, 也阻碍了数据探索和模式发现的效率. 因此, 如何将高维数据降维到低维空间, 同时保留数据的关键结构信息, 成为数据科学领域的一个重要研究方向.
针对这些挑战, UMAP #cite(<mcinnes2018umap>) 和t-SNE #cite(<maaten2008visualizing>) 等降维算法提供了不同的解决方案. 本文将从理论和实践角度探讨这些算法的优缺点, 并通过实验分析它们在数据降维与可视化中的表现.


= 国外文献讨论

== UMAP 与 t-SNE 技术细节对比

UMAP(Uniform Manifold Approximation and Projection)
和 t-SNE(t-Distributed Stochastic Neighbor Embedding)是两种广泛应用于高维数据降维与可视化的非线性方法, 它们的目标相似, 但技术实现上存在显著差异.

1. 理论基础:
  - t-SNE: 基于概率分布, 在高维空间中计算数据点之间的条件概率(表示相似性), 并在低维空间中用 t 分布重新建模这些概率. 其优化目标是最小化高维和低维空间之间的 Kullback-Leibler(KL)散度 #cite(<csiszarKL>) .
  - UMAP: 基于拓扑学和黎曼几何, 构建高维数据的模糊拓扑结构并在低维空间中优化其等效结构. UMAP 的优化目标是最小化交叉熵损失函数.
2. 计算效率:
  - t-SNE: 计算复杂度较高, 尤其是在计算高维空间中的条件概率时, 时间复杂度为 $O(n^2)$, 其中 $n$ 是样本数量. 使得 t-SNE 在处理大规模数据集时效率较低.
  - UMAP: 通过使用 $k$ 最近邻搜索(如 k-NN 算法 #cite(<Altman01081992>) )和随机优化方法, 显著降低了计算复杂度, 时间复杂度接近 $O(n log n)$ , 使其能够更高效地处理大规模数据.
3. 参数敏感性:
  - t-SNE: 主要参数是困惑度, 它控制局部邻域的大小. 困惑度的选择对结果影响较大, 且通常需要通过实验调整.
  - UMAP: 主要参数包括局部邻域大小和低维空间中点的分布密度. UMAP 对这些参数的敏感性较低, 且其默认值通常能够产生较好的结果.

== 性能对比

1. 局部与全局结构保留:
  - t-SNE: 在保留局部结构方面表现优异, 但往往难以捕捉全局结构, 例如数据点之间的远距离关系. 这可能导致在低维空间中, 不同类别的簇之间的距离不一致.
  - UMAP: 在保留局部结构的同时, 能够更好地捕捉全局结构. 这使得 UMAP 在可视化复杂数据集时, 能够更准确地反映数据的整体分布.
2. 可视化效果:
  - t-SNE: 的可视化结果通常具有较高的簇内紧密度, 但簇间的相对距离可能失真. 例如, 在 MNIST 数据集的实验中, t-SNE 能够清晰地分离不同数字类别, 但类别之间的距离可能不一致.
  - UMAP: 的可视化结果在簇内紧密度和簇间距离方面表现更为均衡. 例如, 在单细胞 RNA 测序数据的实验中, UMAP 能够清晰地展示细胞亚群的分布, 同时保持亚群之间的相对距离.
3. 可扩展性:
  - t-SNE: 在处理大规模数据集时效率较低, 难以扩展到数十万甚至数百万样本的数据集.
  - UMAP: 的高效算法使其能够轻松处理大规模数据集, 在大量样本的数据集上, UMAP 的计算时间显著少于 t-SNE.

== 适用领域

1. t-SNE 的适用领域:
  - 小规模数据集: t-SNE 适用于样本数量较少的数据集.
  - 局部结构分析: 当研究重点在于数据的局部结构(如聚类分析)时, t-SNE 是一个合适的选择.
2. UMAP 的适用领域:
  - 大规模数据集: UMAP 适用于大规模数据集, 例如单细胞 RNA 测序数据、社交网络数据或高维图像数据.
  - 全局结构分析: 当需要同时保留数据的局部和全局结构时, UMAP 是更好的选择. 例如, 在生物信息学中, UMAP 被广泛用于单细胞数据的可视化和分析.

== 总结

UMAP 作为一种新兴的非线性降维方法, 与 t-SNE 相比, UMAP 在计算效率和降维效果上都有显著优势. 通过构建高维数据的拓扑结构, UMAP 能够在保留数据局部和全局结构的同时显著提升计算效率; 通过引入更加复杂且可能更符合实际分布的黎曼几何与拓扑学的方法, UMAP 能够更好地捕获数据的内在结构.

t-SNE 由于概率分布的选择和计算复杂度的问题, 在大数据集往往计算效率较低, 且容易过度关注局部结构而忽略全局结构. 但是其相比于 UMAP 更易懂易复现, 对于小规模且不那么复杂的数据集仍然有着不错的表现.

UMAP 和 t-SNE 各有优缺点, 适用于不同的场景. t-SNE 在小规模数据集和局部结构分析中表现优异, 而 UMAP 在大规模数据集和全局结构分析中更具优势. 未来的研究可以进一步探索如何结合两者的优点, 开发更高效的降维算法.

= 降维算法细节

== t-SNE

SNE算法测量所有点相对于其他点的距离, 并将这些距离映射到一个概率分布, 一般选择高斯分布进行拟合.
相对于当前点距离越远则概率越小, 反之则概率越大.
通过最小化原始数据点和低维空间中的点之间的KL散度, SNE算法能够保留数据的局部结构.

t分布从统计特性上能在大数据集上渐进高斯分布, 同时计算量比高斯分布更小.
t-SNE则是在SNE的算法基础上, 将概率分布改为t分布.

=== 高维计算

t-SNE算法假设数据映射到t概率分布, 对于 $x_1, ...,x_N$ 的数据样本点,
如@eq:t-sne_p-condi , t-SNE首先计算出条件概率 $p_{j|i}$ , 其中 $p_{j|i}$ 表示 $x_i$ 与 $x_j$ 之间的相似度,
对于所有 $i$ , $sum_j p_{j|i} eq 1$ .

#box(inset: -0.5em)[
  $
    p_{j|i} = exp(-||x_i - x_j||^2 slash 2sigma_i^2) / (sum_(k!=i)exp(-||x_i-x_k||^2 slash 2sigma^2_i))
  $ <eq:t-sne_p-condi>
]

t-SNE假定了第 $x_i$ 样本点的概率为 $p_i=1/N$ , 根据Bayes公式, $p_(i j)$ 可由@eq:t-sne_pij 计算得到. 因两个点之间的相似度是对称的, 满足 $p_(i j)=p_(j i) and p_(i i)=0 and sum_(i,j)p_(i j)=1$ .

#box(inset: -0.5em)[
  $
    p_{i|j} = N p_(i j)
  $ <eq:t-sne_pij>
]

=== 低维计算

t-SNE的目的就是在低维度空间中找到一个和高维空间中的概率分布最相似的分布.
对于 $y_1, ..., y_N$ 等 $y_i in RR^(d)$ 的样本点,
t-SNE定义了如@eq:t-sne_qij 表示概率 $q_(j i)$ 以指代 $y_i$ 与 $y_j$ 之间的相似度.

#box(inset: -0.5em)[
  $
    q_(i j) = (1 + ||y_i - y_j||^2)^(-1) / (sum_k sum_(l!=k)(1 + ||y_k - y_l||^2)^(-1))
  $ <eq:t-sne_qij>
]

=== 数据降维

t-SNE通过最小化KL散度来优化低维空间中的点的位置, 使其尽可能接近高维空间中的点.
KL散度的定义如@eq:t-sne_kl 表示. 而最小化方法则使用梯度下降.
最终得到的使得KL散度最小的 $y_i$ 作为将维后的数据.

#box(inset: -0.5em)[
  $
    K L(P || Q) = sum_(i!=j)p_(i j)log p_(i j) / q_(i j)
  $ <eq:t-sne_kl>
]

== UMAP

UMAP的理论基础建立在黎曼几何和拓扑学之上, 基于流形分析和图计算的方法,
其通过构建高维数据的拓扑结构并优化低维嵌入,
能够同时保留数据的局部和全局特征. UMAP的理论基础要远比 t-SNE 复杂,
但是 UMAP 的优势在于其计算效率和降维效果.

=== 高维图构建

以 $X={x_1,...,x_N}$ 代表输入样本集, 以k-NN构建高维图.
对于每个 $x_i$ , 选择其 $k$ 个最近邻居, 以 $x_i$ 为中心构建一个高维图. 通过计算 $x_i$ 与其邻居之间的距离,
以高斯核函数计算权重, 构建高维图的邻接矩阵. 基于黎曼几何距离定义 $d(a, b)$ 为 $a$ ,
$b$ 两点间的距离. 则 $x_i$与 $k$ 个邻居的最近距离 $rho_i$ 定义如@eq:umap_rho-i , 其标准差由@eq:umap_sigma-i 得到.

#box(inset: -0.5em)[
  $
    rho_i = min{d(x_i, x_(i_j)) | i <= j <= k, d(x_i, x_(i_j)) > 0}
  $ <eq:umap_rho-i>
]

#box(inset: -0.5em)[
  $
    sum^k_(j=1) exp((-max(0, d(x_i, x_(i_j)) - rho_i)) / sigma_i) = log_2k
  $ <eq:umap_sigma-i>
]

基于上述定义, 可以计算出高维图的权重矩阵 $W$ , @eq:umap_weight 展示了图中每条边的权重计算. 为平衡两点之间的边权重,
UMAP引入了对称归一化的权重矩阵 $W'$ . 对于某个矩阵 $A$ 其对称归一化矩阵可由 $B=A+A^T- A circle.stroked.small A^T$
得到, 其中 $circle.stroked.small$ 表示Hadamard积.

#box(inset: -0.5em)[
  $
    w((x_i, x_(i_j))) = exp((-max(0, d(x_i, x_(i_j)) - rho_i))/sigma_i)
  $ <eq:umap_weight>
]

=== 低维图构建

#let yisubj = $||y_i - y_j||$

对于低维点 $y_i,...,y_j$ , UMAP 模拟了两种力的作用, 一种是吸引力, 一种是斥力. 通过将两种力进行模拟退火的计算方法得到低维嵌入. 吸引力定义如@eq:umap_attra , 斥力定义如@eq:umap_force , 其中 $a , b$ 均为超参数,

#move(dy: -1em)[

  #box(inset: -0.5em)[
    $
      (-2 a b yisubj_2^(2(b-1))) / (1+yisubj_2^2) w((x_i, x_j)) times (y_i-y_j)
    $ <eq:umap_attra>
  ]

  #box(inset: -0.5em)[
    $
      (2b) / ((epsilon + yisubj_2^2) (1 +a yisubj_2^(2b))) (1- w((x_i,x_j))) times (y_i - y_j)
    $ <eq:umap_force>
  ]]

=== 数据降维

UMAP 通过交叉熵梯度下降的方式最小化高维图和低维图, 由于在高维图构建时较好地捕获了数据的拓扑结构, 认为在低维图中也能保留数据的局部和全局特征. 通过最小化高维图和低维图的交叉熵, UMAP 能够找到最优的低维嵌入.

= 解决方案

根据UMAP 和 t-SNE 的相关特性, 选择两种不同规模的数据集进行实验, 以比较两种算法的性能和计算效率.

在算法实现上, 我们基于UMAP官方实现和t-SNE的`scikit-learn` 实现, 对两种不同规模进行降维与可视化.

= 实验与验证

== 实验数据集

数据集分别为企鹅数据集 #cite(<penguinData>) 和手写数字数据集 #cite(<optical_recognition_of_handwritten_digits_80>) .
@table:datasets 展示了两个数据集的维数、样本数和类别数.

#set table.hline(stroke: 0.5pt)
#set table.vline(stroke: 0.5pt)

#lib.table-maker(
  align: center,
  stroke: none,
  columns: 3,
  rows: 2,
  table.hline(),
  [],
  [企鹅数据集],
  [手写数字数据集],
  table.hline(),
  [维数],
  table.vline(),
  [4],
  [64],
  [样本数],
  [443],
  [1797],
  [类别数],
  [3],
  [10],
  table.hline(stroke: 0.5pt),
) <table:datasets>

== 二维降维与可视化结果对比

由@img:umap-penguin 和@img:tsne-penguin 可以看出, UMAP 和 t-SNE 在企鹅数据集上的降维效果和可视化结果有明显差异.
UMAP 得到的数据要更加集中, 而 t-SNE 得到的数据较为分散. 这说明 UMAP 在保留数据全局结构方面表现更好.

由@img:umap-digits 和@img:tsne-digits 可以看出, UMAP 降维后的数据点之间的交叉少, 每个簇更加集中,
而 t-SNE 降维后的数据点分布较为分散, 且不同簇之间的交叉明显.

#v(-1em)

#grid(columns: 2, rows: 4)[
  #lib.graph(path: "../penguins_umap.svg", caption: "UMAP企鹅数据集降维可视化", width: 90%) <img:umap-penguin>
][
  #lib.graph(path: "../penguins_tsne.svg", caption: "t-SNE企鹅数据集降维可视化", width: 90%) <img:tsne-penguin>
][
  #move(dx: 0.8em)[#lib.graph(
      path: "../digits_umap.svg",
      caption: "UMAP手写数字数据集降维可视化",
      width: 100%,
    ) <img:umap-digits>
  ]
][
  #move(dx: 0.6em)[#lib.graph(
      path: "../digits_tsne.svg",
      caption: "t-SNE手写数字数据集降维可视化",
      width: 100%,
    ) <img:tsne-digits>]
]

== 计算效率对比

由@table:time-diff 可以看出, UMAP 在计算效率上明显优于 t-SNE. 在企鹅数据集上, UMAP 的计算时间约为 0 秒, 而 t-SNE 的计算时间约为 1.6 秒;
在手写数字数据集上, UMAP 的计算时间约为 1.1 秒, 而 t-SNE 的计算时间约为 6.2 秒. 这说明 UMAP 在处理大规模数据集时具有明显优势.


#lib.table-maker(
  columns: 3,
  stroke: none,
  table.hline(),
  [],
  table.vline(),
  [企鹅数据集],
  [手写数字数据集],
  table.hline(),
  [UMAP计算时间(s)],
  [$approx 0$],
  [1.6],
  [t-SNE计算时间(s)],
  [1.1],
  [6.2],
  table.hline(),
) <table:time-diff>


= 总结与体会

本文深入探讨了 UMAP 和 t-SNE 两种降维算法的原理、实现细节和优劣势. 通过对两种算法的理论基础和计算效率进行对比, 我们发现 UMAP 在保留数据局部和全局结构的同时显著提升计算效率, 在大规模数据集上具有明显优势. 通过实验验证, 我们发现 UMAP 在降维效果和计算效率上优于 t-SNE, 能够更好地捕捉数据的内在结构. 通过此次课程, 我不仅了解到了更多领域的相关知识, 也认识到了自己的不足之处, 在实验过程中遇到了很多问题, 但是通过不断的尝试和学习, 最终还是得到了满意的结果. 通过这次实验, 我对数据降维与可视化有了更深入的理解, 也提升了自己的编程能力和数据分析能力. 希望在未来的学习和工作中, 能够更好地应用所学知识, 不断提升自己的能力.


#pagebreak()

#lib.make-bibliography(source: "cites.bib")
