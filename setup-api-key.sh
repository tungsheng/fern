#!/bin/bash
# Setup script for fern API key using separate secrets file
# Run: ./setup-api-key.sh

set -e

SECRETS_FILE="$HOME/.env.secrets"
SHELL_CONFIG=""

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    echo "Unsupported shell. Please manually add to your shell config."
    exit 1
fi

echo "fern API Key Setup"
echo "==================="
echo ""
echo "Select your AI provider:"
echo "  1) Cursor (CURSOR_API_KEY)"
echo "  2) OpenAI (OPENAI_API_KEY)"
echo "  3) Anthropic (ANTHROPIC_API_KEY)"
echo "  4) OpenAI-compatible (OPENAI_COMPAT_API_KEY) - Ollama, Groq, Together, etc."
echo ""
read -p "Enter choice [1-4]: " PROVIDER_CHOICE

case "$PROVIDER_CHOICE" in
    1) ENV_VAR="CURSOR_API_KEY"; PROVIDER_NAME="Cursor" ;;
    2) ENV_VAR="OPENAI_API_KEY"; PROVIDER_NAME="OpenAI" ;;
    3) ENV_VAR="ANTHROPIC_API_KEY"; PROVIDER_NAME="Anthropic" ;;
    4) ENV_VAR="OPENAI_COMPAT_API_KEY"; PROVIDER_NAME="OpenAI-compatible" ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
esac

echo ""

# Check if secrets file already exists
if [ -f "$SECRETS_FILE" ]; then
    echo "Secrets file already exists: $SECRETS_FILE"
else
    echo "Creating secrets file: $SECRETS_FILE"
    touch "$SECRETS_FILE"
    chmod 600 "$SECRETS_FILE"
    echo "Created and secured with permissions 600"
fi

# Check if already sourced in shell config
if grep -q "\.env\.secrets" "$SHELL_CONFIG" 2>/dev/null; then
    echo "Secrets file already sourced in $SHELL_CONFIG"
else
    echo "Adding source command to $SHELL_CONFIG"
    echo "" >> "$SHELL_CONFIG"
    echo "# Source environment secrets (API keys)" >> "$SHELL_CONFIG"
    echo "[ -f ~/.env.secrets ] && source ~/.env.secrets" >> "$SHELL_CONFIG"
    echo "Updated shell configuration"
fi

echo ""
echo "Enter your $PROVIDER_NAME API key:"
read -s API_KEY

if [ -z "$API_KEY" ]; then
    echo "No API key provided. Exiting."
    exit 1
fi

# Check if key already exists in secrets file
if grep -q "$ENV_VAR" "$SECRETS_FILE" 2>/dev/null; then
    echo ""
    echo "$ENV_VAR already exists in $SECRETS_FILE"
    echo "Do you want to replace it? (y/N)"
    read -r REPLACE

    if [[ "$REPLACE" =~ ^[Yy]$ ]]; then
        grep -v "$ENV_VAR" "$SECRETS_FILE" > "$SECRETS_FILE.tmp"
        mv "$SECRETS_FILE.tmp" "$SECRETS_FILE"
        echo "export $ENV_VAR=\"$API_KEY\"" >> "$SECRETS_FILE"
        echo "API key updated"
    else
        echo "Setup cancelled"
        exit 0
    fi
else
    echo "export $ENV_VAR=\"$API_KEY\"" >> "$SECRETS_FILE"
    echo "API key saved"
fi

# Ensure permissions are correct
chmod 600 "$SECRETS_FILE"

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Reload your shell: source $SHELL_CONFIG"
echo "2. Verify: echo \$$ENV_VAR"
echo "3. Test in Neovim: :checkhealth fern"
echo ""

# Show provider config hint
case "$PROVIDER_CHOICE" in
    1) echo "Config hint: require('fern').setup({ api = { provider = 'cursor' } })" ;;
    2) echo "Config hint: require('fern').setup({ api = { provider = 'openai' } })" ;;
    3) echo "Config hint: require('fern').setup({ api = { provider = 'anthropic' } })" ;;
    4) echo "Config hint: require('fern').setup({ api = { provider = 'openai_compat' } })" ;;
esac

echo ""
echo "Security reminders:"
echo "- Never commit $SECRETS_FILE to git"
echo "- File permissions: $(ls -la $SECRETS_FILE | awk '{print $1}')"
echo "- Dotfiles git? Add .env.secrets to .gitignore"
