#!/bin/bash
set -euo pipefail

# https://stackoverflow.com/a/21372328
if [ "$(id -u)" -ne 0 ]; then echo "Please run as root." >&2; exit 1; fi

echo "{{secrets_github_token_pass}}" | podman login "{{podman_registry_name}}" -u "{{secrets_github_token_user}}" --password-stdin

# oap-portal
podman pull FIXME
