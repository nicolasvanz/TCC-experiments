import sys, os
import pandas as pd


def main():
	path = "../results/cooked/"+csvfile
	df = pd.read_csv(path)

	# df = df.groupby(["time"]).mean()

	mean = df["time"].mean()

	print(mean)

if __name__ == "__main__":
	global program, csvfile

	program, csvfile = sys.argv
	main()