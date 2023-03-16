import os
import re
import math
import copy
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt

from argparser import init_parser


def customize_and_save_plot(originaldf, col, mapx, mapy, outfilesuffix, ylim=(None, None), col_wrap=None, xlogarithmic=False, xonlyeven=False):
    df = originaldf.copy()

    outputfilepath_name, outputfilepath_ext = os.path.splitext(args.outputfilepath)

    if xlogarithmic:
        # add logarithmic scale for mapx for uniform spacing in x axis
        df[mapx] = df[mapx].apply(lambda x : math.log2(x) + 1 if x != 0 else x)

    # build facet grid
    facet_grid = sb.FacetGrid(df, col=col, sharey=False, sharex=False, col_wrap=col_wrap, aspect=1)
    facet_grid.map(sb.barplot, mapx, mapy, color="black", width=1, dodge=False)
    
    # for axe in facet_grid.axes.flat:
    #     axe.relim()
    #     axe.autoscale_view()
    #     axe.margins(y=0.1)

    for axe in facet_grid.axes.flat:
        for patch in axe.patches:
            current_width = patch.get_width()
            diff = current_width - 0.8
            patch.set_width(0.8)
            patch.set_x(patch.get_x() + diff * .5)

    # set custom xticks
    xticks = sorted(list(set(df[mapx].to_list())))
    xtickslabels= sorted(list(set(originaldf[mapx].to_list())))
    if xonlyeven:
        xticks = list(filter(lambda x: x%2 == 0, xticks))
        xtickslabels = list(filter(lambda x: x%2 == 0, xtickslabels))

    facet_grid.set(
        xticks=xticks,
        xticklabels=xtickslabels,
        ylim=ylim,
    )

    for ax in facet_grid.axes:
	    for p in ax.patches:
             ax.annotate("%d" % p.get_height(), (p.get_x() + p.get_width() / 2., p.get_height()),
                 ha='center', va='center', fontsize=8, color='black', xytext=(0, 5),
                 textcoords='offset points')

    for axe in facet_grid.axes.flat:
        # add y axis grid linesplt.
        for yticklabel in axe.get_yticklabels():
            axe.axhline(int(yticklabel.get_text()), color="grey", linewidth=0.005, ls="--")

        # axe.set_ylabel("Time (ms)")

    # automatically adjust subplots padding
    facet_grid.fig.tight_layout()

    plt.savefig(outputfilepath_name + outfilesuffix + outputfilepath_ext)

def main():
    df = build_dataframe()

    #rename parameters and columns
    new_columns_names = {
        "time":"milissegundos",
        "pages":"páginas",
        "threads":"threads"
    }
    df = df.rename(columns=new_columns_names)

    customize_and_save_plot(
        df, "páginas", "threads", "milissegundos", "_pages",
        ylim=(0, 120),
        col_wrap=3,
        xonlyeven=True
    )

    customize_and_save_plot(
        df, "threads", "páginas", "milissegundos", "_threads",
        ylim = (0, 120),
        col_wrap=3,
        xlogarithmic=True
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