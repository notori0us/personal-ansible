#!/usr/bin/env bash
# Bootstrap ansible itself + collections on a fresh machine.
# Idempotent: re-running is safe.
set -euo pipefail

cd "$(dirname "$0")"

OS=$(uname)
echo "==> bootstrap on $OS"

# Make sure brew + ~/.local/bin are on PATH even from a non-login shell
if [ "$OS" = "Darwin" ] && [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ "$OS" = "Darwin" ] && [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$PATH"

# 1) ensure pipx is available
if ! command -v pipx >/dev/null 2>&1; then
    echo "==> installing pipx"
    if [ "$OS" = "Darwin" ]; then
        if ! command -v brew >/dev/null 2>&1; then
            echo "ERROR: Homebrew not installed. Install it from https://brew.sh first." >&2
            exit 1
        fi
        brew install pipx
    else
        sudo apt-get update
        sudo apt-get install -y pipx
    fi
    pipx ensurepath
fi

# 2) ensure ansible is installed via pipx
if ! command -v ansible >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/ansible" ]; then
    echo "==> installing ansible via pipx"
    pipx install --include-deps ansible
fi

# Make sure ~/.local/bin is in PATH for the rest of this session
export PATH="$HOME/.local/bin:$PATH"

# 3) install required collections
echo "==> installing required ansible collections"
ansible-galaxy collection install -r requirements.yml

cat <<'NOTE'

Bootstrap complete.

Next steps:

  1. (Optional) Sign in to 1Password CLI for the secrets phase:
       op signin

  2. Run the main playbook against this machine:
       ansible-playbook playbooks/site.yml --limit localhost -K

     (-K prompts for sudo password; needed for apt/brew/system-level installs.)

  3. Once 1Password is installed, signed in, and op is on PATH, run the secrets phase:
       ansible-playbook playbooks/secrets.yml --limit localhost

NOTE
