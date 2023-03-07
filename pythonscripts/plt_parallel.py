import os
import re
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt

from argparser import init_parser

def main():
    df = build_dataframe()
    sb.barplot(x="clusters", y="time", data=df, errorbar="sd", errwidth=2)
    plt.savefig(args.outputfilepath)

def build_dataframe():
    path = args.inputdirpath
    df_lines = []
    for filename in os.listdir(path):
        filepath = os.path.join(path, filename)
        if os.path.isfile(filepath):
            clusters = list(map(int, re.split('_|-|\.', filename)[1:2]))[0]
            df = pd.read_csv(filepath)
            mean = df["time"].mean()
            mean = mean / args.frequency * 1000 #milliseconds
            df_lines.append([clusters, mean])
    df = pd.DataFrame(df_lines, columns=["clusters", "time"])
    df = df.sort_values(by=["clusters"])
    return df

if __name__ == "__main__":
    args = init_parser()
    main()