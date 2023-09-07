import os
import re
import math
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt
import scipy.stats as st

from argparser import init_parser

def customize_and_save_plot(
        originaldf, hue, mapx, mapy, outfilesuffix, xlogarithmic=False
):
    df = originaldf.copy()

    outputfilepath_name, outputfilepath_ext = os.path.splitext(args.outputfilepath)

    if xlogarithmic:
        # add logarithmic scale for mapx for uniform spacing in x axis
        df[mapx] = df[mapx].apply(lambda x : int(math.log2(x) + 1) if x != 0 else x)

    sb.set(font_scale=1.7)
    sb.set_style("whitegrid")

    plt.figure(figsize=(18,6.5))
    barplot = sb.barplot(
        x=mapx, y=mapy, hue=hue, data=df, color=(.3,.3,.3),
        linewidth=1, edgecolor=(.3,.3,.3), errorbar=("ci", 95), errcolor="black"
    )
    barplot.set(xlabel="Threads", ylabel="Tempo (ms)")

    for g in barplot.patches:
        barplot.annotate(
            "%d" % g.get_height(),
            (g.get_x() + g.get_width() / 2., g.get_height() + 2),
            ha = 'center', va = 'center',
            xytext = (0, 9),
            textcoords = 'offset points',
            fontsize=14
        )

    plt.legend(title="Páginas")

    plt.tight_layout()
    plt.savefig(outputfilepath_name + outfilesuffix + outputfilepath_ext)

def main():
    df = build_dataframe()

    # add 1 to threads because we want to start from 1 and not 0
    df["threads"]=df["threads"].apply(lambda x : x + 1)
    df["milissegundos"]=df["milissegundos"].apply(lambda x : x/args.frequency*1000)

    # filtering out threads that are not powers of 2
    df = df[df["threads"].isin([2**i for i in range(5)])]

    customize_and_save_plot(
        df, "páginas", "threads", "milissegundos", "_threads2",
        xlogarithmic=False,
    )

def build_dataframe():
    path = args.inputdirpath
    df_result = pd.DataFrame()
    for filename in os.listdir(path):
        filepath = os.path.join(path, filename)
        if os.path.isfile(filepath):
            threads, pages = map(int, re.split('_|-|\.', filename)[2:4])
            df = pd.read_csv(filepath)
            df.rename(columns={"time": "milissegundos"}, inplace=True)
            df["threads"] = threads
            df["páginas"] = pages
            mean = df["milissegundos"].mean()
            mean = mean / args.frequency * 1000 #milliseconds
            df_result = pd.concat([df, df_result])

    df_result = df_result.sort_values(by=["threads", "páginas"])
    return df_result

if __name__ == "__main__":
    args = init_parser()
    main()