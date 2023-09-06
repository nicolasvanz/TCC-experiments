import os
import re
import math
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt
import scipy.stats as st

from argparser import init_parser


PRINT_INFO=False


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
        x=mapx, y=mapy, hue=hue, data=df, color="black",
        linewidth=1, edgecolor="black", errorbar=("ci", 95), errcolor="red"
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

def build_dataframe2():
    path = args.inputdirpath
    df_lines = []
    info_stds = []
    info_confidence_intervals = []
    for filename in os.listdir(path):
        filepath = os.path.join(path, filename)
        if os.path.isfile(filepath):
            threads, pages = map(int, re.split('_|-|\.', filename)[2:4])
            df = pd.read_csv(filepath)
            mean = df["time"].mean()
            if (PRINT_INFO):
                print(f"\n{filename} statistics: 95% confidence interval and std")
                # 95% confidence interval
                confidence_interval = list(map(lambda x: x/args.frequency * 1000, st.t.interval(
                    confidence=0.95,
                    df=len(df["time"])-1,
                    loc=mean,
                    scale=st.sem(df["time"])
                )))
                info_confidence_intervals.append(confidence_interval)
                print(confidence_interval)
                # std
                std = df["time"].std()/args.frequency*1000
                info_stds.append(std)
                print(std)
            mean = mean / args.frequency * 1000 #milliseconds
            df_lines.append([threads, pages, mean])
    if (PRINT_INFO):
        stds_as_string = "\n".join(map(lambda x: "%f" % (x), sorted(info_stds)))
        print(f"\nMultiple Threads Sorted Stds:\n{stds_as_string}")

        info_confidence_intervals.sort(key = lambda x: x[1] - x[0])
        confidence_intervals_as_string = "\n".join(map(lambda x: "[%f - %f]" % (x[0], x[1]), info_confidence_intervals))
        print(f"\nMultiple Threads Sorted confidence intervals:\n{confidence_intervals_as_string}")

    df = pd.DataFrame(df_lines, columns=["threads", "páginas", "milissegundos"])
    df = df.sort_values(by=["threads", "páginas"])
    return df

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

    print(df_result)
    # df = pd.DataFrame(df_lines, columns=["threads", "páginas", "milissegundos"])
    df_result = df_result.sort_values(by=["threads", "páginas"])
    return df_result

if __name__ == "__main__":
    args = init_parser()
    main()