import os
import re
import math
import copy
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt

from argparser import init_parser


def customize_and_save_plot(
        originaldf, col, mapx, mapy, outfilesuffix, ylim=(None, None),
        col_wrap=None, xlogarithmic=False, aspect=1, adjust_tick_fn=None
):
    df = originaldf.copy()

    outputfilepath_name, outputfilepath_ext = os.path.splitext(args.outputfilepath)

    if xlogarithmic:
        # add logarithmic scale for mapx for uniform spacing in x axis
        df[mapx] = df[mapx].apply(lambda x : math.log2(x) + 1 if x != 0 else x)

    # custom xticks
    xticks = sorted(list(set(df[mapx].to_list())))
    xtickslabels= sorted(list(set(originaldf[mapx].to_list())))

    # build facet grid
    facet_grid = sb.FacetGrid(df, col=col, sharey=False, sharex=False, col_wrap=col_wrap, aspect=aspect,)
    facet_grid.map(sb.barplot, mapx, mapy, color="black", order=xticks)

    # xticks - 1 because seaborn starts xticks from 0 and our data starts from 1 
    if adjust_tick_fn:
        xticks = list(map(lambda x: x-1, xticks))

    facet_grid.set(
        xticks=xticks,
        xticklabels=xtickslabels,
        ylim=ylim,
    )

    # write value on top of each bar
    for ax in facet_grid.axes:
        for p in ax.patches:
            ax.annotate(
                "%d" % p.get_height(), (p.get_x() + p.get_width() / 2.,
                p.get_height()), ha='center', va='center', fontsize=9,
                color='black', xytext=(0, 5), textcoords='offset points',
            )

    for axe in facet_grid.axes.flat:
        # add y axis grid linesplt.
        for yticklabel in axe.get_yticklabels():
            axe.axhline(int(yticklabel.get_text()), color="grey", linewidth=0.005, ls="--")
        
        # set axis label for each subplot (note: labels only appear in each
        # subplot if the sharey/sharex parameter is set to False)
        # axe.set_ylabel("Time (ms)")
        # axe.set_xlabel(mapx)

    # automatically adjust subplots padding
    facet_grid.fig.tight_layout()
    # plt.tight_layout()


    plt.savefig(outputfilepath_name + outfilesuffix + outputfilepath_ext)

def main():
    df = build_dataframe()

    df["threads"]=df["threads"].apply(lambda x : x + 1)

    customize_and_save_plot(
        df, "páginas", "threads", "milissegundos", "_pages",
        ylim=(0, 120),
        col_wrap=4,
        aspect=1.5,
        adjust_tick_fn=lambda x:x-1,
    )

    customize_and_save_plot(
        df, "threads", "páginas", "milissegundos", "_threads",
        ylim = (0, 120),
        col_wrap=5,
        xlogarithmic=True,
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
    df = pd.DataFrame(df_lines, columns=["threads", "páginas", "milissegundos"])
    df = df.sort_values(by=["threads", "páginas"])
    return df

if __name__ == "__main__":
    args = init_parser()
    main()