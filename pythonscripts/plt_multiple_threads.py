import argparse
import os
import re
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt


def main():
    df = build_dataframe()
    outputfilepath_name, outputfilepath_ext = os.path.splitext(args.outputfilepath)
    
    facet_gridp = sb.FacetGrid(df, col="pages")
    facet_gridp.map(plt.bar, "threads", "time")
    plt.savefig(outputfilepath_name + "_pages" + outputfilepath_ext)

    facet_gridt = sb.FacetGrid(df, col="threads")
    facet_gridt.map(plt.bar, "pages", "time")
    plt.savefig(outputfilepath_name + "_threads" + outputfilepath_ext)

def build_dataframe():
    path = args.inputdirpath
    df_lines = []
    for filename in os.listdir(path):
        filepath = os.path.join(path, filename)
        if os.path.isfile(filepath):
            threads, pages = map(int, re.split('_|-|\.', filename)[2:4])
            df = pd.read_csv(filepath)
            mean = df["time"].mean()
            df_lines.append([threads, pages, mean])
    df = pd.DataFrame(df_lines, columns=["threads", "pages", "time"])
    df = df.sort_values(by=["threads", "pages"])
    return df

def init_parser():
    global args
    parser = argparse.ArgumentParser(
        description="Create plot for multiple threads/pages experiment"
    )
    parser.add_argument(
        "inputdirpath", type=str, help="Path to directory with data"
    )
    parser.add_argument(
        "outputfilepath", type=str, help="Path to output file"
    )
    args = parser.parse_args()

if __name__ == "__main__":
    init_parser()
    main()