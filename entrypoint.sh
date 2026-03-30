#!/bin/bash
set -e

# Filter AWS config to exclude prod profiles, keeping only explicitly allowed sections
if [ -d /tmp/.aws-host ]; then
    mkdir -p "$HOME/.aws"

    [ -f /tmp/.aws-host/config ] && \
        /usr/local/bin/filter-aws-config.sh /tmp/.aws-host/config > "$HOME/.aws/config"

    [ -f /tmp/.aws-host/credentials ] && \
        /usr/local/bin/filter-aws-config.sh /tmp/.aws-host/credentials > "$HOME/.aws/credentials"

    chmod 600 "$HOME/.aws/config" "$HOME/.aws/credentials" 2>/dev/null || true

    # Copy SSO cache so existing login tokens work
    [ -d /tmp/.aws-host/sso ] && cp -r /tmp/.aws-host/sso "$HOME/.aws/"
    [ -d /tmp/.aws-host/cli ] && cp -r /tmp/.aws-host/cli "$HOME/.aws/"
fi

# Link feature-builder CLI from mounted host repo
if ! command -v feature-builder &>/dev/null && [ -f "$HOME/git/feature-builder/packages/server/dist/cli.cjs" ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/git/feature-builder/packages/server/dist/cli.cjs" "$HOME/.local/bin/feature-builder"
fi

exec "$@"
