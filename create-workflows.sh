#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2317
set -Eeuo pipefail
shopt -s inherit_errexit

function main() {
  while IFS= read -r -d '' script; do
    local workflow_name workflow_file
    workflow_name="$(basename "$script" .sh)"
    workflow_file=".github/workflows/${workflow_name}.yaml"

    cat << EOF > "$workflow_file"
name: ${workflow_name}

on:
  workflow_dispatch: {}
  schedule:
    - cron: '$(random_cron "$workflow_name")'

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ${script}
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
EOF
  done < <(find ./packages -type f -name '*.sh' -not -name '.*' -print0)

  exit 0
}

function random_cron() {
  python3 - "$1" << 'EOF'
import sys
import random
random.seed(sys.argv[1], 2)
m = random.randint(0,59)
h = random.randint(0,23)
print('{} {} * * *'.format(m, h))
EOF
}

main "$@"
exit "$?"
