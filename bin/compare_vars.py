#!python
import argparse

from compile_scripts import process_vars_dir


def startswith_arr(comp_str, startswith_arr):
    for skip_string in startswith_arr:
        if comp_str.startswith(skip_string):
            return True
    return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="compare two vars directories looking for differences.")
    parser.add_argument('vars_a', help="Directory #1 to compare")
    parser.add_argument('vars_b', help="Directory #2 to compare")
    parser.add_argument('--skip', action='append', help="Namespaces to ignore; 'secrets' is the default")
    args = parser.parse_args() 
    skip = args.skip

    if skip is None:
        skip = ['secrets']
    else:
        # ignore --skip ''
        skip = [x for x in skip if len(x)>0]

    vars_a_dict = {}
    for (k, v) in process_vars_dir(args.vars_a).iteritems():
        if not startswith_arr(k, skip):
            vars_a_dict[k] = v

    vars_b_dict = {}
    for (k, v) in process_vars_dir(args.vars_b).iteritems():
        if not startswith_arr(k, skip):
            vars_b_dict[k] = v

    vars_a_items = vars_a_dict.items()
    vars_b_items = vars_b_dict.items()
    difference_set = set(vars_a_items) ^ set(vars_b_items)
    different_keys = list(set([x[0] for x in difference_set]))
    for k in sorted(different_keys):
        if vars_a_dict.has_key(k) and vars_b_dict.has_key(k):
            print "{}:\n  {} vs. {}".format(k, vars_a_dict[k], vars_b_dict[k])
        elif vars_a_dict.has_key(k):
            print "{} is missing in {}".format(k, args.vars_b)
        else:
            print "{} is missing in {}".format(k, args.vars_a)
