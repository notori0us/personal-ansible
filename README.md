# personal-ansible

Idempotent provisioning for Chris's personal workstations
(macOS + Debian Linux). Sister repo to `notori0us/dotfiles`,
`notori0us/rdu-nas-ansible`, and `notori0us/sea-k8s-ansible`.

## What it does

Installs and configures, on both macOS and Debian:

- **Packages:** `vim`, `tmux`, `wireguard-tools` (+ Homebrew on macOS)
- **1Password** (GUI + CLI) — the source of truth for secrets
- **Claude Code** (`claude`) — official native installer
- **Dotfiles** — clones [`notori0us/dotfiles`](https://github.com/notori0us/dotfiles) and runs `setup.sh` (idempotent)
- **SSH** — `~/.ssh/config` and `~/.ssh/id_ansible` distributed from 1Password
- **WireGuard** — tunnel config distributed from 1Password

Secrets never live in this repo. They live in 1Password and are read
at playbook runtime via the `op` CLI.

## First run on a fresh machine

```bash
# 1. Clone
git clone https://github.com/notori0us/personal-ansible ~/workspace/personal-ansible
cd ~/workspace/personal-ansible

# 2. Bootstrap ansible + collections
./bootstrap.sh

# 3. Phase 1 — packages, apps, dotfiles (no secrets)
ansible-playbook playbooks/site.yml --limit localhost -K

# 4. Open 1Password app, sign in, enable CLI integration
#    (Settings → Developer → "Integrate with 1Password CLI")
op signin

# 5. Phase 2 — drop SSH config + keys + WireGuard tunnel
ansible-playbook playbooks/secrets.yml --limit localhost
```

## Re-running

Everything is idempotent. Re-run any playbook to converge:

```bash
ansible-playbook playbooks/site.yml --limit localhost -K
```

## Targeting other machines

The inventory contains `localhost` (the host you're running on, via
`connection: local`) and `sagitta` (Linux box, reachable over SSH).

```bash
ansible-playbook playbooks/site.yml --limit sagitta
```

## What lives in 1Password

The `secrets` playbook reads from these items in your Personal vault:

| 1Password item | Type | Field used | Becomes |
| --- | --- | --- | --- |
| `localadmin` | SSH Key | `private key` / `public key` | `~/.ssh/id_ansible{,.pub}` |
| `personal-ssh-config` | Secure Note | note body | `~/.ssh/config` |
| `wireguard-wg0` | Secure Note | note body | `/etc/wireguard/wg0.conf` (optional) |

The SSH Key item is named after the remote username (`localadmin@…` on
managed hosts) but lands at `~/.ssh/id_ansible` because that's the
filename `~/.ssh/config` references. Override item names per-host in
`group_vars/` or inventory if your naming differs — see
`roles/ssh_config/defaults/main.yml`.

If `wireguard-wg0` is missing, the wireguard role no-ops with a friendly
message instead of failing.
