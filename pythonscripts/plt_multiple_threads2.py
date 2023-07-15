import os
import re
import math
import copy
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt
import scipy.stats as st

from argparser import init_parser


PRINT_INFO=False


def customize_and_save_plot(
        originaldf, col, mapx, mapy, outfilesuffix, ylim=(None, None),
        col_wrap=None, xlogarithmic=False, aspect=1, adjust_tick_fn=None
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
        x="threads", y="milissegundos", hue="páginas", data=df, color="black",
        linewidth=1, edgecolor="black"
    )
    barplot.set(xlabel="Threads", ylabel="Milissegundos")

    for g in barplot.patches:
        barplot.annotate(
            "%d" % g.get_height(),
            (g.get_x() + g.get_width() / 2., g.get_height()),
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

    # filtering out threads that are not powers of 2
    df = df[df["threads"].isin([2**i for i in range(5)])]

    customize_and_save_plot(
        df, "threads", "páginas", "milissegundos", "_threads2",
        ylim = (0, 120),
        col_wrap=4,
        aspect=1.5,
        xlogarithmic=False,
    )

def build_dataframe():
    path = args.inputdirpath
    df_lines = []
    for filename in os.listdir(path):
        filepath = os.path.join(path, filename)
        if os.path.isfile(filepath):
            threads, pages = map(int, re.split('_|-|\.', filename)[2:4])
            df = pd.read_csv(filepath)
            mean = df["time"].mean()
            if (PRINT_INFO):
                print(f"\n{filename} statistics: 95% confidence interval and std")
                # 95% confidence interval
                print(list(map(lambda x: x/args.frequency * 1000, st.t.interval(
                    confidence=0.95,
                    df=len(df["time"])-1,
                    loc=mean,
                    scale=st.sem(df["time"])
                ))))
                # std
                print(df["time"].std()/args.frequency*1000)
            mean = mean / args.frequency * 1000 #milliseconds
            df_lines.append([threads, pages, mean])
    df = pd.DataFrame(df_lines, columns=["threads", "páginas", "milissegundos"])
    df = df.sort_values(by=["threads", "páginas"])
    return df

if __name__ == "__main__":
    args = init_parser()
    main()