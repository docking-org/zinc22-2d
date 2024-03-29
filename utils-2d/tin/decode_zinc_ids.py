#!/bin/python
# utils-2d/decode_zinc_ids.py

import sys
import os

digits = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
digits_map = { digit : i for i, digit in enumerate(digits) }
b62_table = [62**i for i in range(12)]
def base62_rev(s):
	tot = 0
	for i, c in enumerate(reversed(s)):
		val = digits_map[c]
		tot += val * b62_table[i]
	return tot

if __name__ == "__main__":
	target = sys.argv[1]
	cnt=0
	maxid=0
	with open(target) as substances:
		b62_table = [62**i for i in range(12)]
		#sys.stderr.write(str(b62_table) + '\n')
		line = substances.readline()
		while line:
			smiles, zincid = line.split()
			assert(len(zincid) == 16)
			b62 = zincid[6:]
			tot = base62_rev(b62)
			#for i, c in enumerate(reversed(b62)):
			#	val = digits.index(c)
			#	tot += val * b62_table[i]
				#sys.stderr.write("{} {} {}\n".format(c, val, tot))
			if tot > maxid:
				maxid=tot
			print("{} {}".format(smiles, tot))
			line = substances.readline()
			cnt += 1
			if (cnt % 5000) == 0:
				sys.stderr.write("{} done\r".format(cnt))
	sys.stderr.write("{} done\n".format(cnt))
	with open("/tmp/{}.maxid".format(os.path.basename(os.path.dirname(target))), 'w') as maxid_f:
	    maxid_f.write("{}".format(maxid))
