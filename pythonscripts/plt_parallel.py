import os
import re
import pandas as pd
import seaborn as sb
import scipy.stats as st
from matplotlib import pyplot as plt

from argparser import init_parser

def main():
    df = build_dataframe()
    df["clusters"]=df["clusters"].apply(lambda x : int(x/2))
    df["time"] = df["time"].apply(lambda x: x/args.frequency*1000)

    sb.set(font_scale=1.7)
    sb.set_style("whitegrid")
    fig = sb.barplot(
        x="clusters", y="time", data=df, color=(.3,.3,.3), errorbar=("ci", 95),
        errcolor="black", edgecolor=(.3,.3,.3)
    )
    fig.set(xlabel="Migrações Paralelas", ylabel="Tempo (ms)")

    for p in fig.patches:
        fig.annotate(
            "%.2f" % p.get_height(), (p.get_x() + p.get_width() / 2.,
            p.get_height()+0.7), ha='center', va='center', fontsize=15,
            color='black', xytext=(0, 5), textcoords='offset points',
        )

    plt.ylim(110, 120)
    plt.tight_layout()
    plt.savefig(args.outputfilepath)

def build_dataframe():
    path = args.inputdirpath
    df_result = pd.DataFrame()
    for filename in os.listdir(path):
        filepath = os.path.join(path, filename)
        if os.path.isfile(filepath):
            clusters = list(map(int, re.split('_|-|\.', filename)[1:2]))[0]
            df = pd.read_csv(filepath)
            df["clusters"] = clusters
            df_result = pd.concat([df_result, df])
    df_result = df_result.sort_values(by=["clusters"])
    return df_result

if __name__ == "__main__":
    args = init_parser()
    main()