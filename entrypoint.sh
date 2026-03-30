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

exec "$@"
