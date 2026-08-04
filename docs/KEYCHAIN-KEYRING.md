# Keychain & Keyring — How They Work in Warchy

## Overview

Two separate subsystems handle credential management in Warchy:

| Subsystem | Tool | Purpose |
|---|---|---|
| **SSH/GPG agent manager** | `keychain` | Starts/reuses `ssh-agent` and `gpg-agent`, persists them across sessions |
| **Secret Service** | `gnome-keyring-daemon` | Stores arbitrary secrets (passwords, tokens) via the D-Bus Secret Service API |

They are complementary, not redundant — `keychain` manages agent sockets, `gnome-keyring` manages the secret store.

---

## keychain

### What it does

`keychain` is a shell front-end for `ssh-agent` and `gpg-agent`. Its key property is **agent persistence**: it starts the agents once and reuses the same running agents across multiple shells and logins by writing environment variables to files under `~/.ssh/.keychain/`.

Without `keychain`, each new terminal would spawn its own agent (or find none), and you would be prompted for your key passphrase every time.

### How it works

1. On first run, it spawns `ssh-agent` (and optionally `gpg-agent`).
2. It writes the agent socket path and PID to `~/.ssh/.keychain/<hostname>-sh` (and `<hostname>-sh-gpg`).
3. On subsequent shell starts it reads those files back with `--eval`, exporting `SSH_AUTH_SOCK` and `SSH_AGENT_PID` into the current shell.
4. If the agent is already running (socket exists, PID live), it skips starting a new one.

### Warchy configuration

Warchy starts keychain from `config/bash/init`, which is sourced on every interactive login:

```bash
if command -v keychain &> /dev/null; then
  _kc_keys=()
  for _kc_key in ~/.ssh/id_*; do
    [[ -f "$_kc_key" ]] && [[ ! "$_kc_key" =~ \.pub$ ]] && _kc_keys+=("$_kc_key")
  done
  if [[ ${#_kc_keys[@]} -gt 0 ]]; then
    _kc_askpass="$WARCHY_PATH/bin/utils/warchy-ssh-askpass"
    if [[ -x "$_kc_askpass" ]]; then
      eval "$(SSH_ASKPASS="$_kc_askpass" SSH_ASKPASS_REQUIRE=force \
        keychain --dir "${KEYCHAIN_DIR:-$HOME/.ssh/.keychain}" --immediate --eval --quiet "${_kc_keys[@]}")"
    else
      unset SSH_ASKPASS_REQUIRE
      eval "$(keychain --dir "${KEYCHAIN_DIR:-$HOME/.ssh/.keychain}" --eval --quiet "${_kc_keys[@]}")"
    fi
    export SSH_ASKPASS_REQUIRE=prefer
  fi
  unset _kc_keys _kc_key _kc_askpass
fi
```

Key details:
- All private keys under `~/.ssh/id_*` are auto-discovered (`.pub` files excluded).
- `--quiet` suppresses banner output.
- `--eval` outputs `export SSH_AUTH_SOCK=...; export SSH_AGENT_PID=...;` which is `eval`-ed into the shell.
- `--immediate` skips keychain's `Press Enter to initialize keys` gate (see below).
- Passphrases are collected by `warchy-ssh-askpass`, which times out instead of blocking the login (see below).
- `SSH_ASKPASS_REQUIRE` is set to `force` only for the keychain call, then restored to `prefer` so pinentry/GUI prompts take over for the rest of the session.
- The socket directory is controlled by `$KEYCHAIN_DIR` (defaults to `~/.ssh/.keychain`).

### Why login used to hang

Two prompts, each unbounded, stood between opening a terminal and getting a shell:

1. **keychain's multi-terminal gate.** Since 3.0.0_beta2, every shell that finds
   keys missing prints `[ 🔑 Press Enter to initialize keys 🔑 ]` and blocks in
   `select()` on `/dev/tty` — no timeout. Pressing Enter in any one terminal
   elects it to run `ssh-add`; the others get notified over a FIFO when it
   finishes. Useful in VS Code, fatal for an unattended `wsl -d warchy`.
   Warchy passes `--immediate`, which contends for the activation lock right
   away and never prints the gate. (`takeover` is unavailable as a result — it
   only exists at that prompt.)
2. **ssh-add's passphrase prompt**, replaced by `warchy-ssh-askpass` below.

With `--immediate`, if a second terminal already owns the activation, this shell
waits for that terminal's result rather than prompting — bounded in practice by
the owner's askpass timeout.

### Passphrase prompt timeout (warchy-ssh-askpass)

`ssh-add`'s built-in terminal prompt waits forever, so an unattended login (or a
terminal opened just to run a command) would hang until someone typed the
passphrase. Warchy routes the prompt through `bin/utils/warchy-ssh-askpass`:

- `SSH_ASKPASS_REQUIRE=force` makes `ssh-add` use the askpass helper even though a tty is available.
- The helper prompts on `/dev/tty` with `read -t`, waiting `$WARCHY_SSH_ASKPASS_TIMEOUT` seconds (default `20`, exported in `config/bash/envs`).
- Pressing `Enter` with no input skips immediately.
- On timeout/skip it exits non-zero: `ssh-add` abandons the key, `keychain` reports `Unable to add keys`, and the shell continues with `SSH_AUTH_SOCK` exported and the agent running — just without that key loaded.
- With no controlling terminal (GUI launcher, systemd unit, cron) it execs `$WARCHY_SSH_ASKPASS_GUI` (default `/usr/bin/lxqt-openssh-askpass`) instead.

Load a skipped key later with `ssh-add ~/.ssh/id_ed25519_github` (the timeout
message prints the exact path) or by running `keycheck`.

A wrong passphrase costs up to 3 × the timeout: `ssh-add` re-invokes the askpass
for each of its retries (`Bad passphrase, try again for …`), and each attempt has
its own timeout.

Tune or disable the timeout in `~/.bashrc`:

```bash
export WARCHY_SSH_ASKPASS_TIMEOUT=60   # longer grace period
export WARCHY_SSH_ASKPASS_TIMEOUT=5    # fail fast on headless boxes
```

### Interaction with SSH

Once `SSH_AUTH_SOCK` is exported, all `ssh`, `git`, `scp`, and related tools automatically use the running agent for authentication. You only enter your passphrase once per agent lifetime (i.e., until a reboot or the agent is killed).

```
ssh-add -l          # list loaded keys
ssh-add ~/.ssh/id_ed25519_github   # manually add a key
ssh-add -D          # remove all keys from agent
```

### Interaction with GPG

`keychain` can also manage `gpg-agent`. When `gpg-agent` is running and `GPG_AGENT_INFO` / `SSH_AUTH_SOCK` are set correctly, GPG signing (e.g., `git commit -S`) and encryption operations use it transparently via `pinentry`.

```
gpg --list-secret-keys     # list keys known to GPG
gpg-connect-agent /bye     # test if gpg-agent is reachable
gpgconf --kill gpg-agent   # restart gpg-agent
```

---

## GNOME Keyring (gnome-keyring-daemon)

### What it does

`gnome-keyring-daemon` implements the [Secret Service API](https://specifications.freedesktop.org/secret-service/) over D-Bus. It stores arbitrary secrets (passwords, API tokens, OAuth credentials) in an encrypted keychain file at `~/.local/share/keyrings/`.

Applications access it via `libsecret` (the `secret-tool` CLI or language bindings), without needing to know where secrets are stored.

### How it works

1. The daemon registers on the session D-Bus bus under `org.freedesktop.secrets`.
2. Clients call `SecretService.OpenSession`, then `Item.GetSecret` / `Item.CreateItem`.
3. The keyring file is unlocked using a master password (prompted via `pinentry` or automatically if no password is set — common in WSL/headless setups).
4. Tools like `git-credential-libsecret`, `docker`, and `npm` can store credentials here.

### Warchy configuration

Warchy starts the daemon from `config/bash/init`:

```bash
if command -v gnome-keyring-daemon &> /dev/null; then
  if ! pgrep -u "$USER" -x gnome-keyring-d >/dev/null 2>&1; then
    gnome-keyring-daemon --daemonize --components=secrets 2>/dev/null
  fi
fi
```

Key details:
- `--components=secrets` starts only the secrets component (not ssh/gpg components, which conflict with `keychain`).
- `--daemonize` forks to the background. The daemon does not export `GNOME_KEYRING_CONTROL` back to the shell, but D-Bus discovery works without it.
- The guard `pgrep` prevents spawning a second daemon on subsequent shell opens.

### Why not use gnome-keyring for SSH/GPG?

`gnome-keyring-daemon` also has `--components=ssh,gpg`, but they conflict with a dedicated `ssh-agent` + `gpg-agent` setup. Warchy uses `keychain` + `gpg-agent` directly, and `gnome-keyring` only for the Secret Service store.

---

## How the pieces fit together

```
Login shell (bash)
  └── config/bash/init
        ├── gnome-keyring-daemon --daemonize --components=secrets
        │     └── D-Bus: org.freedesktop.secrets
        │           └── secret-tool, git-credential-libsecret, etc.
        │
        └── keychain --eval id_ed25519_github
              ├── ssh-agent (socket: ~/.ssh/agent/...)
              │     └── SSH_AUTH_SOCK → ssh, git, scp
              └── gpg-agent (socket: ~/.gnupg/S.gpg-agent)
                    └── GPG signing, pinentry
```

The critical environment variables:

| Variable | Set by | Used by |
|---|---|---|
| `SSH_AUTH_SOCK` | `keychain --eval` | `ssh`, `git`, `ssh-add` |
| `SSH_AGENT_PID` | `keychain --eval` | `ssh-agent` lifecycle |
| `GNOME_KEYRING_CONTROL` | not exported (headless) | `gnome-keyring-daemon` auto-discovery |

---

## Common issues

### SSH agent socket missing in a new terminal

**Symptom:** `SSH_AUTH_SOCK` is empty or points to a dead socket.

**Cause:** The terminal was opened in a way that didn't source `~/.bashrc` → `rc` → `init` (e.g., a non-login shell, a shell spawned by a GUI application, or a tmux pane started before init ran).

**Fix:**

```bash
eval "$(keychain --dir ~/.ssh/.keychain --eval --quiet)"
```

Or simply run `keycheck` — it detects the missing socket and attempts recovery automatically.

### Login skipped the passphrase prompt

**Symptom:** `⏱  No passphrase entered within 20s — continuing without the key.`
followed by `Unable to add keys`; `ssh-add -l` shows no identities and git over
SSH asks for the passphrase.

**Cause:** Expected behaviour — the prompt timed out (or `Enter` was pressed) so
the login could finish. The agent is running; the key just is not loaded.

**Fix:**

```bash
ssh-add ~/.ssh/id_ed25519_github   # the timeout message prints the path
keycheck                           # or let the checker re-run keychain
```

Raise `WARCHY_SSH_ASKPASS_TIMEOUT` in `~/.bashrc` if 20s is too short.

### gnome-keyring-daemon not running

**Symptom:** `secret-tool store` hangs or returns an error; `keycheck` shows gnome-keyring NOT running.

**Fix:**

```bash
gnome-keyring-daemon --daemonize --components=secrets
```

### gpg-agent unreachable

**Symptom:** `gpg-connect-agent /bye` fails; GPG signing fails with "No secret key".

**Fix:**

```bash
gpgconf --kill gpg-agent   # kill stale agent
gpg-connect-agent /bye     # triggers auto-restart
```

Or restart the keychain entirely:

```bash
keychain --stop all
source ~/.config/bash/init
```

---

## keycheck — diagnostics command

`keycheck` is a shell function defined in `config/bash/aliases`. It checks all four layers of the security stack and auto-recovers SSH if possible.

### Running it

```bash
keycheck
```

### What it checks

| Section | Check | Pass condition |
|---|---|---|
| **Installed tools** | `keychain`, `gnome-keyring-daemon`, `gpg-agent`, `ssh-agent`, `secret-tool` | Binary found in `$PATH` |
| **gnome-keyring** | `pgrep -u $USER -x gnome-keyring-d` | Process is running |
| **SSH agent** | `[[ -S "$SSH_AUTH_SOCK" ]]` | Socket file exists; auto-recovers via keychain if not |
| **gpg-agent** | `gpg-connect-agent /bye` | Agent responds to IPC |
| **Secret Service** | `secret-tool store` + `secret-tool lookup` | Round-trip write/read succeeds |
| **SSH keychain** | `ssh-add -l` | Lists loaded keys |

### Example healthy output

```
=== Installed tools ===
✅ keychain
✅ gnome-keyring-daemon
✅ gpg-agent
✅ ssh-agent
✅ secret-tool

=== Daemon state ===
✅ gnome-keyring running
✅ SSH agent at /home/user/.ssh/agent/s.xxx.agent
✅ gpg-agent

=== Secret Service ===
✅ Secret Service store + lookup

=== SSH keychain ===
256 SHA256:... user@host (ED25519)
```

### Recovery commands (manual)

```bash
# Reload the full init (re-runs keychain + gnome-keyring startup)
source ~/.config/bash/init

# Re-eval keychain only (restores SSH_AUTH_SOCK in current shell)
eval "$(keychain --dir ~/.ssh/.keychain --eval --quiet)"

# Force-add a key manually
ssh-add ~/.ssh/id_ed25519_github

# Restart gnome-keyring
pkill gnome-keyring-daemon
gnome-keyring-daemon --daemonize --components=secrets

# Restart gpg-agent
gpgconf --kill gpg-agent && gpg-connect-agent /bye

# Nuclear: kill all agents and restart from scratch
keychain --stop all
source ~/.config/bash/init
```
