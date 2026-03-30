# =============================================================================
# Claude Code Docker Container - Extensible Version
# Based on Anthropic's official devcontainer setup
# https://github.com/anthropics/claude-code/tree/main/.devcontainer
# =============================================================================

FROM node:22-bookworm

# Build arguments for customization
ARG TZ=UTC
ARG RUST_VERSION=stable

# Set timezone
ENV TZ="${TZ}"

# =============================================================================
# Base System Packages
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Essential tools
    less \
    git \
    procps \
    sudo \
    curl \
    wget \
    ca-certificates \
    gnupg2 \
    # Shell and terminal
    fzf \
    man-db \
    # Firewall tools (for network isolation) - commented out
    # iptables \
    # ipset \
    iproute2 \
    dnsutils \
    # aggregate \
    # Text processing and editors
    jq \
    nano \
    vim \
    ripgrep \
    fd-find \
    tree \
    bat \
    htop \
    unzip \
    zip \
    # Build essentials
    build-essential \
    pkg-config \
    libssl-dev \
    libffi-dev \
    # GitHub CLI
    gh \
    # Networking
    socat \
    # Database client
    postgresql-client \
    # Other stuff
    asciinema \
    libnotify-bin \
    emacs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# =============================================================================
# uv (Python package manager - needed for Serena MCP server)
# =============================================================================
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL=/usr/local/bin sh

# =============================================================================
# Rust Setup (optional - comment out if not needed)
# =============================================================================
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH="/usr/local/cargo/bin:$PATH"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain ${RUST_VERSION} && \
    chmod -R a+w ${RUSTUP_HOME} ${CARGO_HOME}

# =============================================================================
# Node.js Global Setup
# =============================================================================
# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share

# =============================================================================
# User Configuration
# =============================================================================
ARG USERNAME=mark
ARG USER_UID=1000
ARG USER_GID=1000

# Define user home directory
ENV USER_HOME=/home/${USERNAME}

# Create user (the base image has "node" with UID 1000, so we rename it)
RUN usermod -l ${USERNAME} node && \
    groupmod -n ${USERNAME} node && \
    usermod -d /home/${USERNAME} -m ${USERNAME} && \
    sed -i "s|/home/node|/home/${USERNAME}|g" /etc/passwd

# Persist bash history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir -p /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME:$USERNAME /commandhistory

# =============================================================================
# Environment Variables
# =============================================================================
ENV PATH="${USER_HOME}/.local/bin:$PATH"
ENV DEVCONTAINER=true
ENV SHELL=/bin/bash

# Node memory configuration
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Claude configuration
ENV CLAUDE_CONFIG_DIR="${USER_HOME}/.claude"
ENV ENABLE_LSP_TOOLS=1

# =============================================================================
# Firewall Script (for network isolation) - disabled
# =============================================================================
# COPY init-firewall.sh /usr/local/bin/
# RUN chmod +x /usr/local/bin/init-firewall.sh && \
#     echo "${USERNAME} ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/${USERNAME}-firewall && \
#     chmod 0440 /etc/sudoers.d/${USERNAME}-firewall

# =============================================================================
# AWS CLI v2
# =============================================================================
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"; \
    fi && \
    curl -fsSL "$AWS_CLI_URL" -o /tmp/awscliv2.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

# =============================================================================
# Entrypoint & AWS Config Filter
# =============================================================================
COPY entrypoint.sh filter-aws-config.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/filter-aws-config.sh

# =============================================================================
# Workspace Setup
# =============================================================================
RUN mkdir -p ${USER_HOME}/.claude && chown -R $USERNAME:$USERNAME ${USER_HOME}/.claude

# Give user sudo access (optional - remove for tighter security)
# RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME

# =============================================================================
# Install Claude Code (using native installer, as user)
# =============================================================================
RUN curl -fsSL https://claude.ai/install.sh | bash


SHELL ["/bin/bash", "-c"]

# Default command - start interactive shell
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
