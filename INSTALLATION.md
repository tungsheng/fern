# Installation Guide

Complete installation instructions for nvim-cursor.

**Repository:** [github.com/tungsheng/nvim-cursor](https://github.com/tungsheng/nvim-cursor)

---

## Prerequisites

- **Neovim:** >= 0.9.0
- **curl:** For API requests
- **Cursor API Key:** Required for AI features

---

## Quick Install (Recommended)

### 1. Install with lazy.nvim

Add to your Neovim configuration:

**File:** `~/.config/nvim/lua/plugins/nvim-cursor.lua`

```lua
return {
  "tungsheng/nvim-cursor",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "<leader>ae", mode = "v", desc = "AI: Explain selection" },
    { "<leader>aE", mode = "n", desc = "AI: Explain buffer" },
    { "<leader>ac", mode = { "n", "v" }, desc = "AI: Custom prompt" },
    { "<leader>ad", mode = "v", desc = "AI: Generate docs" },
    { "<leader>ar", mode = "v", desc = "AI: Refactor code" },
    { "<leader>af", mode = "v", desc = "AI: Fix bug" },
    { "<leader>at", mode = { "n", "v" }, desc = "AI: Toggle output" },
    { "[a", mode = "n", desc = "AI: Previous in history" },
    { "]a", mode = "n", desc = "AI: Next in history" },
  },
}
```

### 2. Set API Key

**Quick Setup with Script:**
```bash
# Clone the repository
git clone https://github.com/tungsheng/nvim-cursor.git
cd nvim-cursor

# Run the setup script
./setup-api-key.sh
```

**Or Manual Setup:**
```bash
# Add to your shell config (~/.zshrc or ~/.bashrc)
export CURSOR_API_KEY="your_api_key_here"

# Reload shell
source ~/.zshrc  # or source ~/.bashrc

# Verify
echo $CURSOR_API_KEY
```

### 3. Restart Neovim

```bash
nvim
```

### 4. Verify Installation

```vim
:checkhealth nvim-cursor
```

---

## Alternative Installation Methods

### Using packer.nvim

```lua
use {
  "tungsheng/nvim-cursor",
  config = function()
    require("nvim-cursor").setup()
  end
}
```

### Using vim-plug

```vim
Plug 'tungsheng/nvim-cursor'

lua << EOF
require("nvim-cursor").setup()
EOF
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/tungsheng/nvim-cursor.git ~/.local/share/nvim/site/pack/plugins/start/nvim-cursor

# In your init.lua
require("nvim-cursor").setup()
```

---

## Configuration

### Basic Configuration

```lua
{
  "tungsheng/nvim-cursor",
  opts = {
    api = {
      cursor = {
        model = "gpt-4",
        timeout = 30000,
      }
    },
    ui = {
      output = {
        position = "right",  -- "right", "bottom", "left"
        size = 50,           -- percentage
      }
    }
  }
}
```

### Advanced Configuration

```lua
{
  "tungsheng/nvim-cursor",
  config = function()
    require("nvim-cursor").setup({
      api = {
        cursor = {
          model = "gpt-4-turbo",
          timeout = 60000,
          max_retries = 3,
        }
      },
      ui = {
        output = {
          position = "bottom",
          size = 40,
          auto_scroll = true,
        }
      },
      keymaps = {
        enabled = true,
        mappings = {
          explain_selection = "<leader>xe",
          custom_prompt = "<leader>xp",
        }
      },
      log = {
        level = "warn",
        use_file = true,
      }
    })
  end
}
```

---

## API Key Setup (Detailed)

### Option 1: Separate Secrets File (Most Secure)

This approach keeps API keys isolated and easier to manage.

```bash
# Create secrets file
touch ~/.env.secrets

# Secure the file
chmod 600 ~/.env.secrets

# Add API key
echo 'export CURSOR_API_KEY="your_api_key_here"' >> ~/.env.secrets

# Source from shell config
echo '[ -f ~/.env.secrets ] && source ~/.env.secrets' >> ~/.zshrc

# Reload
source ~/.zshrc

# Verify
echo $CURSOR_API_KEY
```

**Benefits:**
- Single file for all secrets
- Easy to backup/restore
- Easy to exclude from version control
- Organized security management

### Option 2: Direct in Shell Config

```bash
# For zsh (macOS default)
echo 'export CURSOR_API_KEY="your_api_key"' >> ~/.zshrc
source ~/.zshrc

# For bash (Linux default)
echo 'export CURSOR_API_KEY="your_api_key"' >> ~/.bashrc
source ~/.bashrc
```

### Option 3: Session-Only

```bash
# Only for current terminal session
export CURSOR_API_KEY="your_api_key"
```

---

## Local Development Setup

For contributing or testing local changes:

```bash
# Clone the repository
git clone https://github.com/tungsheng/nvim-cursor.git
cd nvim-cursor

# In your Neovim config, use local path
{
  "tungsheng/nvim-cursor",
  dir = "~/path/to/nvim-cursor",  -- Your local clone
  dev = true,
  opts = {}
}
```

---

## Verification

### Check Health

```vim
:checkhealth nvim-cursor
```

Expected output:
- ✓ Neovim version 0.9+
- ✓ curl found
- ✓ CURSOR_API_KEY is set
- ✓ API connection successful
- ✓ Plugin configuration loaded
- ✓ Log directory exists

### Test Module Loading

```vim
:luafile test-manual.lua
```

### Test Commands

```vim
" Open help
:help nvim-cursor

" Try a command
:CursorExplain

" Check keymaps
:map <leader>ae
```

---

## Troubleshooting

### Plugin Not Loading

```vim
" Check if loaded
:lua =vim.g.loaded_nvim_cursor

" Force load
:Lazy load nvim-cursor
```

### API Key Not Found

```bash
# Check if set
echo $CURSOR_API_KEY

# If empty, add to shell config
export CURSOR_API_KEY="your_key"

# Restart Neovim
```

### Keymaps Not Working

```vim
" Check for conflicts
:verbose map <leader>ae

" Disable default keymaps if needed
opts = {
  keymaps = { enabled = false }
}
```

### Connection Issues

```lua
-- Increase timeout
opts = {
  api = {
    cursor = {
      timeout = 60000,  -- 60 seconds
      max_retries = 5
    }
  }
}
```

---

## Uninstallation

### Remove Plugin

**lazy.nvim:**
- Remove from your plugin configuration
- Run `:Lazy clean`

**packer.nvim:**
- Remove from config
- Run `:PackerClean`

### Remove Configuration

```bash
# Remove log file
rm ~/.cache/nvim/nvim-cursor.log

# Remove API key (if using separate file)
# Edit ~/.env.secrets and remove the CURSOR_API_KEY line

# Or remove from shell config
# Edit ~/.zshrc or ~/.bashrc and remove the export line
```

---

## Getting Help

- **Documentation:** See [README.md](README.md), [QUICKSTART.md](QUICKSTART.md)
- **Issues:** [github.com/tungsheng/nvim-cursor/issues](https://github.com/tungsheng/nvim-cursor/issues)
- **Discussions:** [github.com/tungsheng/nvim-cursor/discussions](https://github.com/tungsheng/nvim-cursor/discussions)

---

## Next Steps

After installation:

1. Read [QUICKSTART.md](QUICKSTART.md) for basic usage
2. See [KEYMAPS.md](KEYMAPS.md) for all available keymaps
3. Check [TESTING.md](TESTING.md) to verify everything works
4. Review [SECURITY.md](SECURITY.md) for security best practices
5. Customize configuration to your needs

---

## Contributing

Want to help improve nvim-cursor?

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/nvim-cursor.git
cd nvim-cursor

# Make changes and test
nvim --cmd "luafile test-manual.lua"

# Submit pull request
# See README.md for contribution guidelines
```

**Repository:** [github.com/tungsheng/nvim-cursor](https://github.com/tungsheng/nvim-cursor)
