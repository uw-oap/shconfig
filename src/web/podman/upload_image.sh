#!/bin/bash
set -e
PROJECT=$1
BRANCH=$2
PYTHON=python3

if [ -z "$CR_PAT" -o -z "$GITHUB_USERNAME" -o -z "$PROJECT" -o -z "$BRANCH" ]
then
    echo "Specify the GITHUB_USERNAME and CR_PAT variables, and project. Please see"
    echo "  CR_PAT: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token"
    echo "GITHUB_USERNAME=x CR_PAT=x upload_image.sh portal|prime|lux|rt branch"
    exit 1
fi

echo $CR_PAT | podman login "{{podman_registry_name}}" -u "$GITHUB_USERNAME" --password-stdin

# ensure we can SSH to github
eval $(ssh-agent)
ssh-add

if [ "$PROJECT" == "FIXME" ]
then
    for repo_image in FIXME FIXME
    do
	$PYTHON "{{driver_rundir}}/podman/repo_to_registry.py" \
		--git_path "{{FIXME_repo}}" \
		--git_branch "$BRANCH" \
		--podman_file podman/$repo_image \
		--repo_path "{{podman_registry_path}}" \
		--image_name $repo_image
    done
fi
