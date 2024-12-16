
# 1 t-SNE的定义

- t-SNE 是一种非线性降维技术，主要用于高维数据的可视化。它能有效地将高维数据映射到二维或三维空间中，同时保持数据的局部结构。
- t-SNE 将高维数据中的相似性度量转化为低维空间中的相似性度量，通过最小化两者之间的 Kullback-Leibler 散度来实现降维。t-SNE 的核心在于将原始高维空间的距离关系映射到低维空间中，尽量保持数据的邻近关系。

![三个类的二维数据集](/img/三个类的二维数据集.PNG)
![处理后的一维数据集](/img/处理后的一维数据集.PNG)
# 2 数学原理
## 2.1 SNE的核心步骤
### 2.1.1 将欧氏距离转化为条件概率来表征点间相似度
SNE算法的第一步是测量一个点相对于其他点的距离。我们不是直接处理这些距离，而是将它们映射到一个概率分布。
![映射](/img/映射.PNG)

---
在分布中，相对于当前点距离最小的点有很高的概率，而远离当前点的点有很低的概率。
![概率分布](/img/概率分布.PNG)

---
再看2D图，由于蓝色的点团比绿色的点团更分散，如果我们不解决比例上的差异，绿色点的概率将大于蓝色点的概率。为了解释这一事实，我们需要进行归一化。
![除概率总和](/img/除概率总和.PNG)
因此，尽管两点之间的绝对距离不同，但它们被认为是相似的。

---
数学上，正态分布的方程如下：
$P(x)=\frac{1}{\sigma\sqrt{2\pi}}e^\frac{-(x-\mu)^2}{2\sigma^2}$
给定高维空间的数据点：
$x_1,x_2,...,x_n,p_{i|j}$
则可得出以$x_i$自己为中心，以高斯分布选择$x_j$作为近邻点的条件概率公式：
$p_{j|i}=\frac{exp(-\|x_i-x_j\|^2/2\sigma_i^2)}{\Sigma_{k\not=i}exp(-\|x_i-x_k\|^2/2\sigma_i^2)}$

---
同理，有低维空间的映射点：
$y_1,y_2,...,y_n$
分别对应：
$x_1,x_2,...,x_n$
$q_(j|i)$是$y_i$以自己为中心，以高斯分布选择$y_j$作为近邻点的条件概率：
$q_{j|i}=\frac{exp(-\|y_i-y_j\|^2)}{\Sigma_{k\not=i}exp(-\|y_i-y_k\|^2)}$
![一维数据集](/img/一维数据集.PNG)

### 2.1.2 使用梯度下降算法来使低维分布学习/拟合高维分布
SNE的目标是让低维分布去拟合高维分布，则目标是令两个分布一致。两个分布的一致程度可以使用相对熵（也叫做KL散度）来衡量，可以以此定义代价函数:
$C=\sum_iKL(P_i\|Q_i)=\sum_i\sum_jp_{j|i}log\frac{p_{j|i}}{q_{j|i}}$
对C进行梯度下降即可以学习到合适的$y_i$
$\frac{\partial C}{\partial y_i}=2\Sigma_j(p_{j|i}-q_{j|i}+p_{i|j}-q_{i|j})(y_i-y_j)$
![KL散度的变化](/img/KL散度的变化.gif)
![KL散度的变化](/img/KL散度的变化.PNG)
## 2.2 t-SNE的优化
### 2.2.1 拥挤问题
- 在二维映射空间中，能容纳（高维空间中的）中等距离间隔点的空间，不会比能容纳（高维空间中的）相近点的空间大太多
- 换言之，哪怕高维空间中离得较远的点，在低维空间中留不出这么多空间来映射。于是到最后高维空间中的点，尤其是远距离和中等距离的点，在低维空间中统统被塞在了一起，这就叫做“拥挤问题”
- 拥挤问题带来的一个直接后果，就是高维空间中分离的簇，在低维中被分的不明显（但是可以分成一个个区块）。比如用SNE去可视化MNIST数据集的结果如下：
![SNE可视化MINST](/img/SNE可视化MINST.webp)
### 2.2.2 t分布的引用
t-分布的概率密度函数形式为：
$f(t)=\frac{\Gamma(\frac{\nu+1}{2})}{\sqrt{\nu\pi}\Gamma(\frac{\nu}{2})}(1+\frac{t^2}{\nu})^{-\frac{\nu+1}{2}}$
其中$\nu$为自由度
我们在低维空间的分布中，把原先用的高斯分布（自由度为$\infty$）改成自由度为1的分布（把尾巴抬高）。下图可以很好地说明为什么“把尾巴抬高”可以很好地缓解拥挤问题。
![sigma的影响](/img/sigma的影响.GIF)

---
采用t-SNE对MNIST数据集的降维可视化效果:
![t-SNE对MINST数据集的降维可视化效果](/img/t-SNE对MINST数据集的降维可视化效果.gif)

![[/img/80次迭代.gif]]
### 2.2.3 困惑度
- 使用t-SNE时，除了指定想要降维的维度，另一个重要的参数是困惑度（Perplexity）
- 困惑度大致表示如何在局部或者全局位面上平衡关注点，再说的具体一点就是关于对每个点周围邻居数量猜测。困惑度对最终成图有着复杂的影响。
- 使用算法来确定σ_i则要求用户预设困惑度,然后算法找到合适的$σ_i$值让条件分布$P_i$的困惑度等于用户预定义的困惑度即可。
$Perp(P_i)=2^{H(P_i)}=2^{-\Sigma_jp_{j|i}log_2p_{j|i}}$
![[/img/不同困惑度.webp]]
![[/img/不同困惑度2.png]]
# 3 代码示例
```
import matplotlib.pyplot as plt
from sklearn.datasets import load_digits
from sklearn.manifold import TSNE
import seaborn as sns

# 加载数据集
digits = load_digits()
X, y = digits.data, digits.target

# t-SNE 降维
tsne = TSNE(n_components=2, random_state=42, perplexity=30, n_iter=1000)
X_embedded = tsne.fit_transform(X)

# 可视化
plt.figure(figsize=(10, 8))
sns.scatterplot(
    x=X_embedded[:, 0],
    y=X_embedded[:, 1],
    hue=y,
    palette=sns.color_palette("tab10", len(set(y))),
    legend="full"
)
plt.title("t-SNE Visualization of Digits Dataset")
plt.xlabel("Dimension 1")
plt.ylabel("Dimension 2")
plt.show()

```