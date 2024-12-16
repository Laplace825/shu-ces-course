import numpy as np

import matplotlib.pyplot as plt

from mpl_toolkits.mplot3d import Axes3D

fig = plt.figure(figsize=(15, 10))

# 3 三个三维空间中的簇

# 使用 t-SNE 进行降维

x = np.random.normal(1, 1, 1000)
y = np.random.normal(1, 1, 1000)
z = np.random.normal(1, 1, 1000)

x2 = np.random.normal(7, 0.2, 1000)
y2 = np.random.normal(7, 1.0, 1000)
z2 = np.random.normal(7, 0.02, 1000)

x3 = np.random.normal(4, 0.2, 1000)
y3 = np.random.normal(3, 0.02, 1000)
z3 = np.random.normal(4, 0.12, 1000)

# fig = plt.figure()
ax1 = fig.add_subplot(121, projection="3d")

ax1.scatter(x, y, z, label="Cluster 1", s=3, marker="o", c="purple")
ax1.scatter(x2, y2, z2, label="Cluster 2", s=3, marker="o", c="red")
ax1.scatter(x3, y3, z3, label="Cluster 3", s=3, marker="o", c="green")

ax1.set_title("3D Clusters (1000 points each)")
ax1.legend()

# plt.savefig("gen_3d_clusters.png")
# plt.close()
print("3D Clusters (1000 points each) saved as gen_3d_clusters.png")

from sklearn.manifold import TSNE

X = np.array([x, y, z]).T
X2 = np.array([x2, y2, z2]).T
X3 = np.array([x3, y3, z3]).T

X = np.concatenate((X, X2, X3))

X_embedded = TSNE(n_components=2).fit_transform(X)

# fig = plt.figure()
ax2 = fig.add_subplot(122)

ax2.scatter(
    X_embedded[:1000, 0],
    X_embedded[:1000, 1],
    label="Cluster 1",
    s=3,
    marker="o",
    c="purple",
)
ax2.scatter(
    X_embedded[1000:2000, 0],
    X_embedded[1000:2000, 1],
    label="Cluster 2",
    s=3,
    marker="o",
    c="red",
)
ax2.scatter(
    X_embedded[2000:, 0],
    X_embedded[2000:, 1],
    label="Cluster 3",
    s=3,
    marker="o",
    c="green",
)

ax2.set_title("2D Clusters (1000 points each)")
ax2.legend()

plt.savefig("gen_clusters.png")
plt.close()
