# Security Guide

This document outlines security best practices for using nvim-cursor safely.

## Table of Contents

- [API Key Management](#api-key-management)
- [Separate Secrets File Setup](#separate-secrets-file-setup)
- [File Permissions](#file-permissions)
- [Version Control Safety](#version-control-safety)
- [Advanced Options](#advanced-options)
- [Security Checklist](#security-checklist)

## API Key Management

### Golden Rules

1. **NEVER** commit API keys to version control
2. **NEVER** hardcode keys in Lua config files
3. **ALWAYS** use environment variables
4. **ALWAYS** secure your secrets file with proper permissions

### Why Separate Secrets File?

Keeping API keys in a separate file offers several advantages:

- **Isolation**: Keys are isolated from general configuration
- **Portability**: Share dotfiles publicly without exposing secrets
- **Manageability**: One place to manage all sensitive credentials
- **Gitignore-friendly**: Easy to exclude from version control
- **Multiple environments**: Different keys for dev/prod without config changes

## Separate Secrets File Setup

### Quick Setup (Automated)

Use the provided setup script:

```bash
# Run the interactive setup
./setup-api-key.sh

# Follow the prompts to:
# 1. Create ~/.env.secrets
# 2. Set proper permissions (600)
# 3. Add API key
# 4. Update shell config to source the file
```

### Manual Setup (Step-by-Step)

#### Step 1: Create the Secrets File

```bash
# Create the file
touch ~/.env.secrets

# Verify it was created
ls -la ~/.env.secrets
```

#### Step 2: Secure the File

**Critical**: Set restrictive permissions immediately:

```bash
# Only you can read/write this file
chmod 600 ~/.env.secrets

# Verify permissions
ls -la ~/.env.secrets
# Should show: -rw------- (600)
```

#### Step 3: Add Your API Key

```bash
# Option A: Use echo (be careful with shell history)
echo 'export CURSOR_API_KEY="your_api_key_here"' >> ~/.env.secrets

# Option B: Edit manually (more secure)
vim ~/.env.secrets
# or
nano ~/.env.secrets

# Add this line:
# export CURSOR_API_KEY="your_actual_api_key"
```

#### Step 4: Source in Shell Config

**For zsh (macOS/Linux default):**

```bash
# Add to ~/.zshrc
echo '# Source environment secrets' >> ~/.zshrc
echo '[ -f ~/.env.secrets ] && source ~/.env.secrets' >> ~/.zshrc

# Reload
source ~/.zshrc
```

**For bash:**

```bash
# Add to ~/.bashrc
echo '# Source environment secrets' >> ~/.bashrc
echo '[ -f ~/.env.secrets ] && source ~/.bashrc' >> ~/.bashrc

# Reload
source ~/.bashrc
```

#### Step 5: Verify Setup

```bash
# Check variable is set
echo $CURSOR_API_KEY

# Open a NEW terminal window and check again
echo $CURSOR_API_KEY

# Test in Neovim
nvim -c "checkhealth nvim-cursor" -c "qa"
```

## File Permissions

### Understanding File Permissions

The `600` permission means:
- `6` (owner): read (4) + write (2) = 6
- `0` (group): no permissions
- `0` (others): no permissions

### Check Current Permissions

```bash
ls -la ~/.env.secrets
```

Expected output:
```
-rw-------  1 username  staff  XX bytes  date  .env.secrets
```

### Fix Incorrect Permissions

If permissions are too open:

```bash
# Fix it immediately
chmod 600 ~/.env.secrets

# Verify
ls -la ~/.env.secrets
```

### Why This Matters

Loose permissions (e.g., `644` or `755`) allow other users on your system to read your API keys. Always use `600` for sensitive files.

## Version Control Safety

### Gitignore Configuration

The project `.gitignore` already includes:

```gitignore
# Environment secrets (API keys, tokens)
.env.secrets
*.env.local
.env.*.local
```

### If You Track Dotfiles

If you version control your home directory dotfiles:

```bash
# Add to your dotfiles .gitignore
cd ~  # or wherever your dotfiles repo is
echo '.env.secrets' >> .gitignore
echo '*.env.local' >> .gitignore

# Verify secrets file won't be tracked
git status  # .env.secrets should not appear

# If it appears in git status:
git rm --cached ~/.env.secrets  # Remove from git index
```

### Verify Before Committing

Always check before committing:

```bash
# Search for potential API keys in staged files
git diff --cached | grep -i "api_key"
git diff --cached | grep -i "cursor_api"

# Check what files are staged
git status

# If secrets file appears, remove it
git reset ~/.env.secrets
```

## Advanced Options

### Password Manager Integration

For maximum security, use a password manager:

#### 1Password CLI

```bash
# Install 1Password CLI
brew install --cask 1password-cli

# Sign in
eval $(op signin)

# Store your key in 1Password, then in ~/.env.secrets:
echo 'export CURSOR_API_KEY=$(op read "op://Personal/Cursor API/credential")' >> ~/.env.secrets
```

#### pass (Unix Password Manager)

```bash
# Install pass
brew install pass  # macOS
# or
apt install pass  # Linux

# Initialize pass (one-time setup)
pass init your-gpg-id

# Store your API key
pass insert cursor-api-key

# In ~/.env.secrets:
echo 'export CURSOR_API_KEY=$(pass show cursor-api-key)' >> ~/.env.secrets
```

#### Bitwarden CLI

```bash
# Install Bitwarden CLI
brew install bitwarden-cli

# Login
bw login

# In ~/.env.secrets:
echo 'export CURSOR_API_KEY=$(bw get password "Cursor API")' >> ~/.env.secrets
```

### Environment-Specific Keys

Manage different keys for different environments:

```bash
# In ~/.env.secrets
if [ "$ENVIRONMENT" = "production" ]; then
    export CURSOR_API_KEY="prod_key_here"
else
    export CURSOR_API_KEY="dev_key_here"
fi
```

### Multiple API Keys

If you use multiple AI services:

```bash
# In ~/.env.secrets
export CURSOR_API_KEY="your_cursor_key"
export OPENAI_API_KEY="your_openai_key"
export ANTHROPIC_API_KEY="your_anthropic_key"
```

## Security Checklist

Before using nvim-cursor, verify:

- [ ] API key is in `~/.env.secrets`, not in Lua config
- [ ] `~/.env.secrets` has `600` permissions
- [ ] `.env.secrets` is in `.gitignore` (both project and dotfiles)
- [ ] Shell config sources `~/.env.secrets` on startup
- [ ] Environment variable is set: `echo $CURSOR_API_KEY` returns value
- [ ] New terminal sessions have the variable set
- [ ] `:checkhealth nvim-cursor` passes all checks
- [ ] No API keys appear in git history: `git log -p | grep -i api_key`

### After Setup

- [ ] Test the plugin with a simple request
- [ ] Check logs don't contain sensitive data: `~/.cache/nvim/nvim-cursor.log`
- [ ] Verify the plugin warns if key is hardcoded (test by temporarily adding to config)

### Regular Maintenance

- [ ] Rotate API keys periodically
- [ ] Review file permissions regularly
- [ ] Check `.gitignore` effectiveness before commits
- [ ] Audit shell history for exposed keys: `history | grep -i api_key`

## What To Do If Key Is Compromised

If you accidentally commit your API key:

1. **Immediately revoke the key** in your Cursor account
2. **Generate a new API key**
3. **Update `~/.env.secrets`** with the new key
4. **Remove from git history**:
   ```bash
   # Use BFG Repo-Cleaner or git-filter-repo
   # DO NOT use git filter-branch (it's deprecated)
   
   # With git-filter-repo:
   git filter-repo --invert-paths --path .env.secrets
   
   # Force push (WARNING: rewrites history)
   git push --force
   ```
5. **Notify your team** if this is a shared repository
6. **Review access logs** in your Cursor account

## Additional Resources

- [Cursor API Security](https://cursor.sh/docs/security)
- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [OWASP: Key Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html)

## Questions?

If you find a security issue, please report it responsibly. Do not open a public issue. Contact the maintainers directly.
