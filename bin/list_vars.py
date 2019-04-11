#!python
import argparse

from compile_scripts import process_vars_dir


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="List all defined variables.")
    parser.add_argument('vars_a', help="Directory to list")
    args = parser.parse_args() 
    vars_a_dict = process_vars_dir(args.vars_a)
    for k in sorted(vars_a_dict.keys()):
        print k
