# fern

[![GitHub](https://img.shields.io/badge/GitHub-tungsheng%2Ffern-blue?logo=github)](https://github.com/tungsheng/fern)
[![Version](https://img.shields.io/badge/version-v0.2.0-blue.svg)](VERSION)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-0.9%2B-brightgreen?logo=neovim)](https://neovim.io)

AI-powered code assistance directly in Neovim with multi-provider LLM support.

**Repository:** [github.com/tungsheng/fern](https://github.com/tungsheng/fern)

## Features

- **Multi-provider** - Cursor, OpenAI, Anthropic (Claude), and OpenAI-compatible (Ollama, Groq, Together)
- **Streaming responses** - See AI output in real-time without blocking your editor
- **Context-aware** - Automatically includes file path, line numbers, and surrounding code
- **Predefined actions** - Explain, document, refactor, and fix bugs with dedicated commands
- **Custom prompts** - Ask anything with visual selection or full buffer context
- **Response history** - Navigate through previous AI responses with `[a` and `]a`
- **Async by default** - Never blocks your editor, cancel anytime with `<C-c>`
- **Secure** - API key via environment variable only, with automatic warnings
- **Health check** - Built-in diagnostics with `:checkhealth fern`
- **Progress indicators** - Visual feedback during streaming with spinner animation
- **Auto-retry** - Automatic retry with exponential backoff for transient errors
- **Structured logging** - Debug mode with sensitive data redaction

## Requirements

- Neovim 0.9+
- curl
- API key for your chosen provider

## Installation

### lazy.nvim (recommended)

```lua
{
  "tungsheng/fern",
  event = "VeryLazy",
  opts = {
    api = {
      provider = "anthropic",  -- or "cursor", "openai", "openai_compat"
    }
  },
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
  "tungsheng/fern",
  config = function()
    require("fern").setup({
      api = { provider = "anthropic" }
    })
  end
}
```

### Setup API Key

**IMPORTANT:** Never store API keys in Lua config files or commit them to git.

**Quick Setup:**

```bash
./setup-api-key.sh
```

**Manual Setup:**

```bash
# For Anthropic (Claude)
export ANTHROPIC_API_KEY="your_key_here"

# For OpenAI
export OPENAI_API_KEY="your_key_here"

# For Cursor
export CURSOR_API_KEY="your_key_here"

# Add to shell config
echo 'export ANTHROPIC_API_KEY="your_key"' >> ~/.zshrc
source ~/.zshrc

# Verify
nvim -c "checkhealth fern" -c "qa"
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

```lua
require("fern").setup({
  api = {
    provider = "anthropic",  -- "cursor" | "openai" | "anthropic" | "openai_compat"
    cursor    = { model = "gpt-4", timeout = 30000 },
    openai    = { model = "gpt-4o", timeout = 30000 },
    anthropic = { model = "claude-sonnet-4-20250514", max_tokens = 4096 },
    openai_compat = {
      endpoint = "http://localhost:11434/v1/chat/completions",
      model = "llama3",
      timeout = 60000,
    },
  },
  ui = {
    output = {
      position = "right",  -- "right", "bottom", "left"
      size = 50,
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
require("fern").setup({
  keymaps = { enabled = false }
})
local actions = require('fern.actions')
vim.keymap.set('v', '<leader>x', actions.explain_selection)
```

**Add custom actions:**

```lua
require("fern").setup({
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
- `:FernExplain`, `:FernDoc`, `:FernRefactor`, `:FernFixBug`
- `:FernPrompt` - Custom prompt
- `:FernToggle` - Toggle output pane
- `:FernCancel` - Cancel request
- `:FernHistoryClear` - Clear history
- `:FernVersion` - Show plugin version
- `:checkhealth fern` - Run diagnostics

## Supported Providers

| Provider | Config Key | Env Variable | Default Model |
|----------|-----------|--------------|---------------|
| Cursor | `cursor` | `CURSOR_API_KEY` | gpt-4 |
| OpenAI | `openai` | `OPENAI_API_KEY` | gpt-4o |
| Anthropic | `anthropic` | `ANTHROPIC_API_KEY` | claude-sonnet-4-20250514 |
| OpenAI-compat | `openai_compat` | `OPENAI_COMPAT_API_KEY` (optional) | llama3 |

The `openai_compat` provider works with any OpenAI-compatible API: Ollama, Groq, Together, vLLM, LM Studio, etc.

## Troubleshooting

Run health check to diagnose issues:

```vim
:checkhealth fern
```

**Enable debug logging:**

```lua
opts = { log = { level = "debug" } }
```

View logs: `~/.cache/nvim/fern.log`

**Common fixes:**
- API key not found - Run `./setup-api-key.sh` or check your provider's env var
- Request timeout - Increase timeout in provider config
- Output pane hidden - Press `<leader>at` to toggle
- Stuck request - Press `<C-c>` to cancel

## Security

**NEVER commit API keys to version control**

- Store keys in `~/.env.secrets` with `chmod 600` permissions
- Add `.env.secrets` to `.gitignore` if tracking dotfiles
- Plugin automatically redacts sensitive data from logs
- Run `:checkhealth fern` to validate security setup

For comprehensive security guidance, see [SECURITY.md](SECURITY.md).

## Architecture

```
User Action -> Context Manager -> API Client -> Provider Dispatch
                                                   |
                               Cursor / OpenAI / Anthropic / OpenAI-compat
                                                   |
                                            Stream Handler
                                                   |
                                 Output Pane (History + Progress)
```

## Contributing

Contributions welcome! Areas for improvement:
- Additional AI providers
- Enhanced UI components
- Diff view and code application
- Report bugs and improve docs

**Development:**

```bash
git clone https://github.com/tungsheng/fern.git
cd fern

# Test locally
nvim --cmd "luafile test-manual.lua"

# Or in your config:
{ "tungsheng/fern", dir = "~/path/to/fern", opts = {} }
```

Submit issues and PRs at [github.com/tungsheng/fern](https://github.com/tungsheng/fern)

## License

MIT License - see LICENSE file for details.
