#!python
# INPUTS:
#  - source directory
#  - variables directory
#  - destination directory
# 
# OUTPUTS:
#
#   Each file in the source directory is written into the destination
#   directory, with any variables replaced.
#
# TODO would be jazzy to use syslog and have a DEBUG switch
import argparse
import json
import os

from jinja2 import Template, StrictUndefined, pass_context


if 'DEBUG' in os.environ and os.environ['DEBUG']:
    DEBUG=True
else:
    DEBUG=False


def read_json_file(var_path, filename):
    """
    Reads `filename` and confirms it's parseable as a JSON dictionary.
    Takes the keys from this dictionary, prepends `var_path_` to them,
    and returns that dictionary.

    For example:
      - INPUT FILE:
          {"test": "a",
           "test2": "b"}
      - var_path of "examplepath"

    will return

       {"examplepath_test": "a",
        "examplepath_test2": "b"}
    """
    vars_fh = open(filename, 'rb')
    json_vars = json.load(vars_fh)
    if not isinstance(json_vars, dict):
        raise Exception("JSON file needs to be a dictionary")

    vars_dict = {}
    for (k, v) in json_vars.items():
        vars_dict["{}_{}".format(var_path, k)] = v
    return vars_dict


def process_vars_dir(vars_dir):
    """
    Recurses through `vars_dir` looking through files.

    Looks at file extensions to figure out how to process each file.

    INPUT:
       - file1.json with content {"a": 1}
       - dir1/file2.json with content {"b": 2}
       - dir1/dir2/file3.json with content {"c": 3}

    OUTPUTS:

      { "file1_a": 1,
        "dir1_file2_b": 2,
        "dir1_dir2_file3_c": 3 }
    """
    vars_dict = {}
    for root, subFolders, files in os.walk(vars_dir):
        for filename in files:
            full_path = os.path.join(root, filename)
            # remove the first first part:
            var_path = full_path.replace(vars_dir, '')
            # change / to _ (TODO this is OS-dependent)
            var_name = var_path.replace('/', '_')
            # get the extension out
            (var_prefix, extension) = os.path.splitext(var_name)

            if extension == '.json':
                vars_dict.update(read_json_file(var_prefix, full_path))
            elif var_path == '.gitignore':
                pass
            else:
                raise Exception("Don't know how to parse {}".format(full_path))

    return vars_dict


# thanks to https://stackoverflow.com/a/3463669
@pass_context
def get_context(c):
    return c


def parse_file(vars_dict, src, dest, ignore_undefined=False):
    """
    Renders filename `src` into `dest` using `vars_dict` as the
    variable names for the template.
    """
    source_fh = open(src, 'r')
    dest_fh = open(dest, 'w')

    if DEBUG:
        print(f"Processing {source_fh} into {dest_fh}")

    if ignore_undefined:
        template = Template(
            source_fh.read())
    else:
        template = Template(
            source_fh.read(),
            undefined=StrictUndefined)
    template.globals['context'] = get_context
    template.globals['callable'] = callable

    applied_template = template.render(**vars_dict)
    dest_fh.write(applied_template)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compile templates using variables.")
    parser.add_argument('source', help="Source directory")
    parser.add_argument('vars', help="Variables directory")
    parser.add_argument('dest', help="Destination directory")
    parser.add_argument('--ignore-undefined', action='store_true', help="Don't error on undefined variables")
    args = parser.parse_args()

    vars_dict = process_vars_dir(args.vars)
    # Add _env_x for each environment variable:
    vars_dict.update({
        "{}_{}".format("_env", k): v for k, v in os.environ.items()
        })

    if not os.path.exists(args.dest):
        os.mkdir(args.dest)

    for root, subFolders, files in os.walk(args.source, followlinks=True):
        for folder in subFolders:
            full_path = os.path.join(root, folder)
            dest_path = full_path.replace(args.source, args.dest)
            if not os.path.exists(dest_path):
                os.mkdir(dest_path)
        for filename in files:
            full_path = os.path.join(root, filename)
            dest_path = full_path.replace(args.source, args.dest)
            parse_file(vars_dict, full_path, dest_path, ignore_undefined=args.ignore_undefined)
