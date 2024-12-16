import numpy as np
import matplotlib.pyplot as plt

np.random.seed(0)
x = np.random.uniform(0, 1, 100)

plt.scatter(x, np.zeros_like(x), label="Scatter", s=10, marker="o")

plt.gca().axes.get_yaxis().set_visible(False)

ax = plt.gca()

ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

ax.spines["bottom"].set_position("zero")
ax.spines["left"].set_visible(False)

ax.plot(1, 0, ">k", transform=ax.get_yaxis_transform(), clip_on=False)

plt.title("1D Uniform Distribution (100 points)")
plt.legend()

plt.savefig("gen_1d.png")
plt.close()

fig = plt.figure(figsize=(10, 10))

ax1 = fig.add_subplot(2, 2, 1)

# 生成 100 个在 0 到 1 之间均匀分布的数
x = np.random.uniform(0, 1, 100)
y = np.random.uniform(0, 1, 100)

# 绘制二维均匀分布的散点图
ax1.scatter(x, y, label="Scatter", s=10, marker="o", c="r")

# 获取当前轴
# ax = plt.gca()

# 隐藏顶部和右侧的脊柱
# ax1.spines["top"].set_color("none")
# ax1.spines["right"].set_color("none")

# 移动底部和左侧的脊柱到数据坐标系的0点
# ax1.spines["bottom"].set_position("zero")
# ax1.spines["left"].set_position("zero")

# ax1.plot(0, 1, "^k", transform=ax1.get_xaxis_transform(), clip_on=False)
# 在X轴末端添加箭头
# ax1.plot(1, 0, ">k", transform=ax1.get_yaxis_transform(), clip_on=False)

ax1.set_title("2D Uniform Distribution (100 points)")
ax1.legend()

# plt.savefig("gen_2d_100.png")
# plt.close()

ax2 = fig.add_subplot(2, 2, 2)
# plt.subplot(2, 2, 2)
# 生成 10000 个在 0 到 1 之间均匀分布的数
x = np.random.uniform(0, 1, 10000)
y = np.random.uniform(0, 1, 10000)

# 绘制二维均匀分布的散点图
ax2.scatter(x, y, label="Scatter", s=10, marker="o", c="orange")

# 获取当前轴
# ax = plt.gca()

# 隐藏顶部和右侧的脊柱
# ax2.spines["top"].set_color("none")
# ax2.spines["right"].set_color("none")

# 移动底部和左侧的脊柱到数据坐标系的0点
# ax2.spines["bottom"].set_position("zero")
# ax2.spines["left"].set_position("zero")

# ax2.plot(0, 1, "^k", transform=ax2.get_xaxis_transform(), clip_on=False)
# 在X轴末端添加箭头
# ax2.plot(1, 0, ">k", transform=ax2.get_yaxis_transform(), clip_on=False)

ax2.set_title("2D Uniform Distribution (10000 points)")
ax2.legend()

# plt.savefig("gen_2d_10000.png")

from mpl_toolkits.mplot3d import Axes3D

ax3 = fig.add_subplot(2, 2, 3, projection="3d")

# plt.subplot(2, 2, 3)
# 生成 10000 个在 0 到 1 之间均匀分布的数
x = np.random.uniform(0, 1, 10000)
y = np.random.uniform(0, 1, 10000)
z = np.random.uniform(0, 1, 10000)

# 创建一个新的图形
# fig = plt.figure()
# ax = fig.add_subplot(111, projection="3d")

# 绘制三维均匀分布的散点图
ax3.scatter(x, y, z, label="Scatter", s=3, marker="o", c="purple")

# 设置标题
ax3.set_title("3D Uniform Distribution (10000 points)")

# 添加图例
ax3.legend()

# 保存图形
# plt.savefig("gen_3d_10000.png")


ax4 = fig.add_subplot(2, 2, 4, projection="3d")
# plt.subplot(2, 2, 4)
# 生成 1000000 个在 0 到 1 之间均匀分布的数
x = np.random.uniform(0, 1, 1000000)
y = np.random.uniform(0, 1, 1000000)
z = np.random.uniform(0, 1, 1000000)

# 创建一个新的图形
# fig = plt.figure()
# ax = fig.add_subplot(111, projection="3d")

# 绘制三维均匀分布的散点图
ax4.scatter(x, y, z, label="Scatter", s=3, marker="o", c="purple")

# 设置标题
ax4.set_title("3D Uniform Distribution (1000000 points)")

# 添加图例
ax4.legend()

# 保存图形
plt.savefig("gen.png")
plt.close()
