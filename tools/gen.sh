#!/bin/bash

# Run code generators.
#
# Usage:
#    ./tools/gen.sh

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "$0")" && pwd)"/..

./tools/target-spec-json.sh
