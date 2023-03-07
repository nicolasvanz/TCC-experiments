import os
import re
import math
import copy
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt

from argparser import init_parser


def customize_and_save_plot(originaldf, col, mapx, mapy, outfilesuffix, ylim=(None, None), col_wrap=None):
    df = originaldf.copy()

    outputfilepath_name, outputfilepath_ext = os.path.splitext(args.outputfilepath)

    # add logarithmic scale for mapx for uniform spacing in x axis
    df[mapx] = df[mapx].apply(lambda x : math.log2(x) + 1 if x != 0 else x)

    # build facet grid
    facet_gridp = sb.FacetGrid(df, col=col, sharey=False, sharex=False, col_wrap=None)
    facet_gridp.map(plt.bar, mapx, mapy)

    # set custom xticks
    facet_gridp.set(
        xticks=sorted(list(set(df[mapx].to_list()))),
        xticklabels=sorted(list(set(originaldf[mapx].to_list()))),
        ylim=ylim
    )

    for axe in facet_gridp.axes.flat:
        # add y axis grid linesplt.
        for yticklabel in axe.get_yticklabels():
            axe.axhline(int(yticklabel.get_text()), color="black", linewidth=0.005, ls="--")

        axe.set_ylabel("Time (ms)")
    
    # automatically adjust subplots padding
    facet_gridp.fig.tight_layout()

    plt.savefig(outputfilepath_name + outfilesuffix + outputfilepath_ext)

def main():
    df = build_dataframe()

    customize_and_save_plot(
        df, "pages", "threads", "time", "_pages",
        ylim=(0, 120),
        col_wrap=4
    )

    customize_and_save_plot(
        df, "threads", "pages", "time", "_threads",
        ylim = (0, 120),
        col_wrap=3
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
            mean = mean / args.frequency * 1000 #milliseconds
            df_lines.append([threads, pages, mean])
    df = pd.DataFrame(df_lines, columns=["threads", "pages", "time"])
    df = df.sort_values(by=["threads", "pages"])
    return df

if __name__ == "__main__":
    args = init_parser()
    main()