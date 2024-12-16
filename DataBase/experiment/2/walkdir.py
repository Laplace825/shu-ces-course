"""
walkdir.py

This script is used to walk through the assets directory 
and generate a list of filenames that start with "2_".

"""

import os
import sys

pwd = os.path.abspath(os.path.dirname(sys.argv[0]))
root_dir = os.path.abspath(os.path.dirname(os.path.dirname(sys.argv[0])))
assets_dir = os.path.join(root_dir, "assets")
filename_array = []

for dirpath, dirnames, filenames in os.walk(assets_dir):
    for filename in filenames:
        if filename.startswith("2_"):
            print(f"../assets/{filename}")
            filename_array.append(f"../assets/{filename}")

# 2_q1.png
filename_array.sort(key=lambda x: int(x.split("_")[1][1]))
print(filename_array)

with open(os.path.join(pwd, "2_q.txt"), "w") as file:
    file.write("\n".join(filename_array))
