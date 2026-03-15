#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Example runs (stub CLI prints usage currently)

echo "Run: small full gossip"
gleam run -- 50 full gossip || true

echo "Run: small line push-sum"
gleam run -- 50 line push-sum || true

