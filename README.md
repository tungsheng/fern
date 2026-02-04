# nvim-cursor

[![GitHub](https://img.shields.io/badge/GitHub-tungsheng%2Fnvim--cursor-blue?logo=github)](https://github.com/tungsheng/nvim-cursor)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-0.9%2B-brightgreen?logo=neovim)](https://neovim.io)

AI-powered code assistance directly in Neovim using the Cursor API.

**Repository:** [github.com/tungsheng/nvim-cursor](https://github.com/tungsheng/nvim-cursor)

## Features

- ✨ **Streaming responses** - See AI output in real-time without blocking your editor
- 🎯 **Context-aware** - Automatically includes file path, line numbers, and surrounding code
- 🔧 **Predefined actions** - Explain, document, refactor, and fix bugs with dedicated commands
- 💬 **Custom prompts** - Ask anything with visual selection or full buffer context
- 📜 **Response history** - Navigate through previous AI responses with `[a` and `]a`
- ⚡ **Async by default** - Never blocks your editor, cancel anytime with `<C-c>`
- 🔐 **Secure** - API key via environment variable only, with automatic warnings
- 🩺 **Health check** - Built-in diagnostics with `:checkhealth nvim-cursor`
- 📊 **Progress indicators** - Visual feedback during streaming with spinner animation
- 🔄 **Auto-retry** - Automatic retry with exponential backoff for transient errors
- 📝 **Structured logging** - Debug mode with sensitive data redaction

## Requirements

- Neovim 0.9+
- curl
- Cursor API key ([get one here](https://cursor.sh))

## Installation

### lazy.nvim (recommended)

```lua
{
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

### packer.nvim

```lua
use {
  "tungsheng/nvim-cursor",
  config = function()
    require("nvim-cursor").setup()
  end
}
```

### Setup API Key

**IMPORTANT:** Never store API keys in Lua config files or commit them to git.

**Quick Setup:**

```bash
# Run the interactive setup script
./setup-api-key.sh
```

**Manual Setup:**

```bash
# Create and secure secrets file
touch ~/.env.secrets
chmod 600 ~/.env.secrets
echo 'export CURSOR_API_KEY="your_api_key_here"' >> ~/.env.secrets

# Source from shell config (zsh/bash)
echo '[ -f ~/.env.secrets ] && source ~/.env.secrets' >> ~/.zshrc
source ~/.zshrc

# Verify
echo $CURSOR_API_KEY
nvim -c "checkhealth nvim-cursor" -c "qa"
```

For detailed security guidance, see [SECURITY.md](SECURITY.md).

## Quick Start

1. Select code in visual mode (`v` or `V`)
2. Press `<leader>ae` to explain, `<leader>ad` to document, or `<leader>ac` for custom prompt
3. View streaming response in split pane
4. Navigate history with `]a` (next) / `[a` (previous)
5. Toggle pane with `<leader>at`, cancel with `<C-c>`

For detailed usage examples, see [QUICKSTART.md](QUICKSTART.md).

## Configuration

Default configuration (customize as needed):

```lua
require("nvim-cursor").setup({
  api = {
    cursor = {
      model = "gpt-4",
      timeout = 30000,
      max_retries = 3
    }
  },
  ui = {
    output = {
      position = "right",  -- "right", "bottom", "left"
      size = 50,           -- percentage
      auto_scroll = true
    }
  },
  keymaps = {
    enabled = true  -- Set false to define your own
  },
  log = {
    level = "warn"  -- "debug" for troubleshooting
  }
})
```

**Customize keymaps:**

```lua
require("nvim-cursor").setup({
  keymaps = { enabled = false }
})
local actions = require('nvim-cursor.actions')
vim.keymap.set('v', '<leader>x', actions.explain_selection)
```

**Add custom actions:**

```lua
require("nvim-cursor").setup({
  custom_actions = {
    add_tests = {
      keymap = "<leader>aT",
      mode = "v",
      system_prompt = "Generate unit tests for this code:"
    }
  }
})
```

## Commands

All actions available as commands:
- `:CursorExplain`, `:CursorDoc`, `:CursorRefactor`, `:CursorFixBug`
- `:CursorPrompt` - Custom prompt
- `:CursorToggle` - Toggle output pane
- `:CursorCancel` - Cancel request
- `:CursorHistoryClear` - Clear history
- `:checkhealth nvim-cursor` - Run diagnostics

## Troubleshooting

Run health check to diagnose issues:

```vim
:checkhealth nvim-cursor
```

**Enable debug logging:**

```lua
opts = { log = { level = "debug" } }
```

View logs: `~/.cache/nvim/nvim-cursor.log`

**Common fixes:**
- API key not found → Run `./setup-api-key.sh` or check `echo $CURSOR_API_KEY`
- Request timeout → Increase `api.cursor.timeout = 60000` or check internet
- Output pane hidden → Press `<leader>at` to toggle
- Stuck request → Press `<C-c>` to cancel

## Comparison

| Feature              | nvim-cursor | copilot.vim | ChatGPT.nvim |
| -------------------- | ---------- | ----------- | ------------ |
| Streaming responses  | ✅          | ❌           | ✅            |
| Context-aware        | ✅          | ✅           | ⚠️ Manual    |
| Custom prompts       | ✅          | ❌           | ✅            |
| Request cancellation | ✅          | N/A         | ❌            |
| Response history     | ✅          | N/A         | ❌            |
| Health check         | ✅          | ❌           | ❌            |
| Auto-retry           | ✅          | N/A         | ❌            |
| Cursor API           | ✅          | ❌           | ❌            |

## Security

⚠️ **NEVER commit API keys to version control**

- Store keys in `~/.env.secrets` with `chmod 600` permissions
- Add `.env.secrets` to `.gitignore` if tracking dotfiles
- Plugin automatically redacts sensitive data from logs
- Run `:checkhealth nvim-cursor` to validate security setup

For comprehensive security guidance including password manager integration, see [SECURITY.md](SECURITY.md).

## Architecture

```
User Action → Context Manager → API Client → Cursor API
                                      ↓
                               Stream Handler
                                      ↓
                    Output Pane (History + Progress)
```

Components: Context extraction, API client with retry logic, SSE stream handler, output pane with history, structured logging with redaction.

## Contributing

Contributions welcome! Areas for improvement:
- Add AI providers (OpenAI, Anthropic, etc.)
- Extend predefined actions
- Enhance UI components
- Add features (diff view, code application)
- Report bugs and improve docs

**Development:**

```bash
git clone https://github.com/tungsheng/nvim-cursor.git
cd nvim-cursor

# Test locally
nvim --cmd "luafile test-manual.lua"

# Or in your config:
{ "tungsheng/nvim-cursor", dir = "~/path/to/nvim-cursor", opts = {} }
```

Submit issues and PRs at [github.com/tungsheng/nvim-cursor](https://github.com/tungsheng/nvim-cursor)

## License

MIT License - see LICENSE file for details.

## Acknowledgments

Built for the Neovim community with inspiration from:
- LazyVim conventions
- Modern AI coding assistants
- Neovim plugin best practices
