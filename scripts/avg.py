
import numpy as np

def compute_stats(table):
  np_array = np.array(table)
  for t in [np.mean, np.std, np.min, np.max]:
    print(t(table))

periodic = [3881.917, 4991.556, 3611.569, 3489.892, 3485.468, 3454.263, 3522.575, 3466.192, 3611.541, 3538.897]
classic = [15825.303, 17572.139, 15742.463, 15096.372, 15368.615, 15357.229, 15161.218, 15559.989, 15657.483, 15603.247]
periodic_seqoff = [4566.602, 3746.519, 4009.217, 3979.657, 4211.831, 3940.124, 4400.986, 4002.761, 4216.185, 3980.555]
classic_seqoff = [1288.993, 1265.563, 1316.657, 1449.269, 1386.136, 1357.199, 1386.974, 1391.699, 1398.684, 1328.875]

print("--- periodic")
compute_stats(periodic)
print("--- classic")
compute_stats(classic)
print("--- periodic_seqoff")
compute_stats(periodic_seqoff)
print("--- classic_seqoff")
compute_stats(classic_seqoff)