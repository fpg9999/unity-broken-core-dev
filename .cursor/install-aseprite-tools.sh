#!/usr/bin/env bash
# Idempotent Cloud Agent install: refresh aseprite-mcp and verify Aseprite CLI.
set -euo pipefail

echo "[aseprite-tools] verifying Aseprite CLI..."
if ! command -v aseprite >/dev/null 2>&1; then
  echo "ERROR: aseprite not on PATH. Rebuild the Cloud Agent Dockerfile." >&2
  exit 1
fi
aseprite --version

MCP_DIR="${ASEPRITE_MCP_DIR:-/opt/aseprite-mcp}"
if [[ ! -d "$MCP_DIR/.git" ]]; then
  echo "[aseprite-tools] cloning aseprite-mcp into $MCP_DIR..."
  mkdir -p "$(dirname "$MCP_DIR")"
  if ! git clone --depth 1 https://github.com/diivi/aseprite-mcp.git "$MCP_DIR" 2>/dev/null; then
    MCP_DIR="${HOME}/aseprite-mcp"
    echo "[aseprite-tools] falling back to $MCP_DIR"
    git clone --depth 1 https://github.com/diivi/aseprite-mcp.git "$MCP_DIR"
    echo "WARNING: update Cloud Agents MCP --directory to $MCP_DIR" >&2
  fi
fi

echo "[aseprite-tools] updating aseprite-mcp deps in $MCP_DIR..."
cd "$MCP_DIR"
git fetch --depth 1 origin HEAD || true
git pull --ff-only || true
uv sync

if [[ ! -f "$MCP_DIR/.env" ]]; then
  printf 'ASEPRITE_PATH=%s\n' "$(command -v aseprite)" > "$MCP_DIR/.env"
fi

mkdir -p ArtSrc/aseprite

echo "[aseprite-tools] smoke: import aseprite_mcp + run aseprite --version via env"
export ASEPRITE_PATH="${ASEPRITE_PATH:-$(command -v aseprite)}"
uv run --directory "$MCP_DIR" python -c "
import os, subprocess
from pathlib import Path
p = os.environ.get('ASEPRITE_PATH', 'aseprite')
print('ASEPRITE_PATH=', p)
print(subprocess.check_output([p, '--version'], text=True).strip())
import aseprite_mcp
print('aseprite_mcp import ok')
"

echo "[aseprite-tools] ready"
