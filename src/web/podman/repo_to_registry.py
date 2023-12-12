#!python
import argparse
import os
import sys
import tempfile


def system_or_die(system_cmd):
    print(f"Running {system_cmd}")
    retval = os.system(system_cmd)
    if retval != 0:
        raise Exception(
            f"system_cmd returned non-zero exit 'retval'")


def get_podman_tags_for_repo(repo_path):
    prev_dir = os.getcwd()
    os.chdir(repo_path)
    tags = [
        os.popen('git rev-parse --short HEAD').read(),
        ]

    version_output = os.popen(
        "git describe --tags --exact-match --match 'v*.*.*' 2>/dev/null").read()
    if version_output:
        version_parts = version_output.split('.')
        tags.extend(
            (
                version_output,
                f'{version_parts[0]}.{version_parts[1]}',
                version_parts[0])
            )

    os.chdir(prev_dir)
    return tags


def repo_to_registry(
        git_path,
        git_branch,
        podman_file,
        repo_path,
        image_name):
    # remove trailing slash
    while repo_path[-1] == '/':
        repo_path = repo_path[:-1]

    local_dir = tempfile.mkdtemp()
    print(f"Copying into {local_dir}")
    system_or_die(
        f'git clone {git_path} {local_dir}')
    os.chdir(local_dir)
    system_or_die(
        f'git checkout {git_branch}')
    system_or_die(
        f'podman build --platform linux/amd64 -t {image_name} --ssh default -f {podman_file} .')

    tags = get_podman_tags_for_repo(
        local_dir)
    tags.append(git_branch.replace('/', '-'))
    tags.append('latest')

    for tag in tags:
        system_or_die(
            f'podman push {image_name} '
            f'{repo_path}/{image_name}:{tag}')


if __name__ == '__main__':
    if 'SSH_AUTH_SOCK' not in os.environ:
        print(
            "Please run: \n"
            "  eval $(ssh-agent)\n"
            "  ssh-add",
            file=sys.stderr)
        sys.exit(1)

    parser = argparse.ArgumentParser(
        description="Repo to Registry tool")
    parser.add_argument('--git_path', required=True)
    parser.add_argument('--git_branch', required=True)
    parser.add_argument('--podman_file', required=True)
    parser.add_argument('--repo_path', required=True)
    parser.add_argument('--image_name', required=True)
    args = parser.parse_args()

    repo_to_registry(
        git_path=args.git_path,
        git_branch=args.git_branch,
        podman_file=args.podman_file,
        repo_path=args.repo_path,
        image_name=args.image_name)
