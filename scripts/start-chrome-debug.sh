#!/usr/bin/env bash
# Launch an isolated Chrome instance with remote debugging enabled.
# Used by the chrome-devtools MCP server inside the Docker container
# (connects via --browserUrl http://127.0.0.1:9222).

exec google-chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-debug
