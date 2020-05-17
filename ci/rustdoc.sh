#!/bin/bash

set -euo pipefail

RUSTDOCFLAGS=-Dwarnings cargo doc --no-deps --all --all-features
