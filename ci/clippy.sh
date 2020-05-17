#!/bin/bash

set -euo pipefail

. ci/install-component.sh clippy

cargo clippy --all --all-features --all-targets
