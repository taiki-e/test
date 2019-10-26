#!/bin/bash

cargo run --target-dir target --manifest-path ci/ci-tools/Cargo.toml "$@"
