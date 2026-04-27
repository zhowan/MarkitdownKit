#!/bin/zsh
set -e

cd "$(dirname "$0")"

mkdir -p .swift-home .build/ModuleCache .build-scratch
HOME="$PWD/.swift-home" \
CLANG_MODULE_CACHE_PATH="$PWD/.build/ModuleCache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/ModuleCache" \
swift run --scratch-path .build-scratch MarkitdownKitMac
