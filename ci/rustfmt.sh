#!/bin/bash

set -euo pipefail

. ci/install-component.sh rustfmt

if [[ "${CI:-false}" == "true" ]]; then
    rustfmt --check --edition 2018 "$(find . -name '*.rs' -print)"
else
    rustfmt --edition 2018 "$(find . -name '*.rs' -print)"
fi
