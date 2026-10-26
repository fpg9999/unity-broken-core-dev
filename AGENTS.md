# Agent notes (unity-broken-core-dev)

## Cursor Cloud — Aseprite pixel art

Cloud Agents that draw pixel art should use the **aseprite** MCP (stdio) configured in the Cloud Agents dashboard from `.cursor/mcp-aseprite.cloud.json`.

- Aseprite is a **CLI-only** build from source (`ENABLE_UI=OFF`, Lua scripting on), pinned to `v1.3.18.6` in `.cursor/Dockerfile`. Do not redistribute that binary.
- MCP server lives at `/opt/aseprite-mcp`; binary at `/usr/local/bin/aseprite`.
- Write sprites under `ArtSrc/aseprite/` (`.aseprite` + exported PNG). Prefer `view_sprite` while iterating; commit source `.aseprite` when the art is approved.
- After changing `.cursor/Dockerfile` or `environment.json`, trigger a new Cloud Agent **Build**, then enable the aseprite MCP and start a cloud chat with the desired model (e.g. Claude Opus).

Local IDE still uses the machine-level Aseprite MCP in `~/.cursor/mcp.json`; cloud uses the dashboard MCP entry separately.
