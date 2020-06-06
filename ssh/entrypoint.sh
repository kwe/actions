#!/bin/sh
set -eu

if [ -z "$INPUT_HOST" ]; then
    echo "Input remote_host is required!"
    exit 1
fi

# Extra handling for SSH-based connections.
if [ ${INPUT_HOST#"ssh://"} != "$INPUT_HOST" ]; then
    SSH_HOST=${INPUT_HOST#"ssh://"}
    SSH_HOST=${SSH_HOST#*@}

    if [ -z "$INPUT_PRIVATE_KEY" ]; then
        echo "Input ssh_private_key is required for SSH hosts!"
        exit 1
    fi

    if [ -z "$INPUT_PUBLIC_KEY" ]; then
        echo "Input ssh_public_key is required for SSH hosts!"
        exit 1
    fi

    echo "Registering SSH keys..."

    # Save private key to a file and register it with the agent.
    mkdir -p "$HOME/.ssh"
    printf '%s' "$INPUT_PRIVATE_KEY" > "$HOME/.ssh"
    chmod 600 "$HOME/.ssh"
    eval $(ssh-agent)
    ssh-add "$HOME/.ssh"

    # Add public key to known hosts.
    printf '%s %s\n' "$SSH_HOST" "$INPUT_PUBLIC_KEY" >> /etc/ssh/ssh_known_hosts
fi

echo "Connecting to $INPUT_HOST..."
ssh -A -tt -o 'StrictHostKeyChecking=no' -p ${PORT:-22} $INPUT_USER@$INPUT_HOST "$*"
