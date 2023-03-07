import os
import re
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt

from argparser import init_parser

def main():
    df = build_dataframe()
    fig = sb.barplot(
        x="clusters", y="time", data=df, errorbar="sd", errwidth=2,
        color="black"
    )
    fig.set(xlabel="Clusters", ylabel="Time (ms)")

    for label in fig.get_yticklabels():
        fig.axhline(int(label.get_text()), color="grey", linewidth=0.5, ls="--")

    plt.ylim(0, 120)
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