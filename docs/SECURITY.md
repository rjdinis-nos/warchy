# Security Policy

## Overview

Warchy is an automated Arch Linux installation and configuration framework designed for development environments, particularly WSL (Windows Subsystem for Linux). This document outlines the security model, considerations, and best practices.

## Security Model

### WSL Development Environment

Warchy is designed for **development environments**, not production servers. The security model reflects this:

- **NOPASSWD Sudo**: The `wheel` group is configured with `NOPASSWD: ALL` for convenience in development
- **User Trust Model**: Assumes the user has physical access to the machine
- **Network Security**: Relies on the host OS (Windows) firewall for network protection

⚠️ **Warning**: Do not use Warchy configurations on production servers or public-facing systems without reviewing and hardening the security settings.

## Secure Practices Implemented

### Installation Security

1. **HTTPS Downloads**: All remote installations use HTTPS
   ```bash
   curl -LsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/main/install.warchy.sh | bash
   ```

2. **Package Verification**: Uses pacman's signature checking for package authenticity

3. **Error Handling**: Comprehensive error handling with `set -eEuo pipefail` in all scripts

4. **File Permissions**: Proper permissions for sensitive files:
   - Sudoers files: `0440`
   - SSH configs: User-only read/write
   - GPG configs: User-only access

### Credential Management

#### API Keys

API keys are **never hardcoded** in the repository. They must be stored in user-specific config directories:

```bash
# Gemini API key location
~/.config/gemini/api_key
```

**Setup Instructions**:
```bash
# Create config directory
mkdir -p ~/.config/gemini

# Add your API key
echo "your-api-key-here" > ~/.config/gemini/api_key
chmod 600 ~/.config/gemini/api_key
```

#### Git Configuration

The git config template includes placeholders that must be customized:

```ini
[user]
    name = Your Name
    email = your.email@example.com
    signingkey = YOUR_GPG_KEY_ID_HERE
```

**After installation**, update these values:
```bash
git config --global user.name "Your Actual Name"
git config --global user.email "your.actual@email.com"
git config --global user.signingkey "YOUR_ACTUAL_GPG_KEY"
```

#### GPG Keys

If using GPG signing:

1. Generate a GPG key: `gpg --full-generate-key`
2. List keys: `gpg --list-secret-keys --keyid-format=long`
3. Configure git: `git config --global user.signingkey YOUR_KEY_ID`

### Docker Security

Docker containers are run with minimal privileges:

```bash
docker run --rm -it \
    -v "$API_KEY_FILE":/root/.config/gemini/api_key:ro \  # Read-only mount
    -e GEMINI_API_KEY="$(cat "$API_KEY_FILE")" \
    "$DOCKER_IMAGE"
```

- API keys mounted as **read-only** (`:ro`)
- Containers removed after exit (`--rm`)
- No privileged mode required

## What's NOT in the Repository

The following sensitive items are excluded via `.gitignore`:

- ❌ API keys (`**/*api_key*`)
- ❌ Private keys (`**/*.key`, `**/*.pem`)
- ❌ Environment files (`**/.env*`)
- ❌ User-specific git configuration (`config/git/config`)
- ❌ GPG private keys (`config/gnupg/`)

## Hardening for Production (Not Recommended)

If you must use Warchy-installed systems in production, apply these hardening steps:

1. **Remove NOPASSWD Sudo**:
   ```bash
   sudo rm /etc/sudoers.d/wheel-nopasswd
   ```

2. **Configure Firewall**:
   ```bash
   sudo pacman -S ufw
   sudo ufw enable
   ```

3. **Enable SELinux/AppArmor**: (if available on your kernel)

4. **Review Exposed Services**: 
   ```bash
   sudo ss -tulpn
   ```

5. **Disable Unnecessary Services**:
   ```bash
   sudo systemctl disable <service>
   ```

6. **Use SSH Keys Only**: Disable password authentication
   ```bash
   # In /etc/ssh/sshd_config
   PasswordAuthentication no
   ```

## Reporting Security Issues

If you discover a security vulnerability in Warchy:

1. **Do NOT** open a public GitHub issue
2. Contact the maintainer directly via email (see GitHub profile)
3. Provide details:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Threat Model

### In Scope

- Hardcoded credentials in repository
- Insecure file permissions in default configs
- Unsafe shell practices (injection vulnerabilities)
- Exposure of sensitive user data

### Out of Scope

- Physical access to the machine
- Compromised Windows host in WSL scenarios
- Social engineering attacks
- Third-party package vulnerabilities (managed by Arch Linux security team)

## Best Practices for Users

1. ✅ **Keep System Updated**:
   ```bash
   sudo pacman -Syu
   ```

2. ✅ **Use Strong Passwords**: Even in development, use non-trivial passwords

3. ✅ **Rotate API Keys**: Regularly rotate external service API keys

4. ✅ **Review Scripts**: Before running any script, review its contents:
   ```bash
   curl -LsSf https://url/script.sh | less  # Review first
   curl -LsSf https://url/script.sh | bash  # Then execute
   ```

5. ✅ **Backup Important Data**: Regular backups prevent data loss

6. ✅ **Use SSH Keys**: Configure SSH key authentication for git operations

7. ✅ **Enable GPG Signing**: Sign your commits for authenticity

## Security Checklist

After installation, verify:

- [ ] No default passwords in use
- [ ] API keys stored securely (600 permissions)
- [ ] Git config updated with real email/name
- [ ] GPG key configured (if using commit signing)
- [ ] SSH keys configured (not using password auth)
- [ ] Docker daemon secured (only accessible by authorized users)
- [ ] No unnecessary services running

## Resources

- [Arch Linux Security](https://wiki.archlinux.org/title/Security)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [GPG Key Management](https://wiki.archlinux.org/title/GnuPG)
- [SSH Security](https://wiki.archlinux.org/title/SSH_keys)

## Version History

- **2025-12-31**: Initial security documentation created
