import argparse

def init_parser():
    parser = argparse.ArgumentParser(
        description="Create plot for multiple threads/pages experiment"
    )
    parser.add_argument(
        "inputdirpath", type=str, help="Path to directory with data"
    )
    parser.add_argument(
        "outputfilepath", type=str, help="Path to output file"
    )
    parser.add_argument(
        "frequency", type=int, help="Processor frequency"
    )
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    print("this module should be imported as a library, not run as a script.")
    exit(1)
