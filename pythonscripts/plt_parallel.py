import argparse
import os
import re
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt


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
            df_lines.append([clusters, mean])
    df = pd.DataFrame(df_lines, columns=["clusters", "time"])
    df = df.sort_values(by=["clusters"])
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