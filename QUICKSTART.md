# Quick Start Guide

Get fern running in 5 minutes.

**Repository:** [github.com/tungsheng/fern](https://github.com/tungsheng/fern)

## Step 1: Get API Key

Choose your provider and get an API key:

**Anthropic (Claude):** [https://console.anthropic.com](https://console.anthropic.com)
**OpenAI:** [https://platform.openai.com](https://platform.openai.com)
**Cursor:** [https://cursor.sh](https://cursor.sh)
**Ollama:** Run locally, no key needed

## Step 2: Set Environment Variable

Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
# For Anthropic
export ANTHROPIC_API_KEY="your_api_key_here"

# Or for OpenAI
export OPENAI_API_KEY="your_api_key_here"

# Or for Cursor
export CURSOR_API_KEY="your_api_key_here"
```

Reload your shell:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

Verify it's set:
```bash
echo $ANTHROPIC_API_KEY  # or your chosen provider's key
```

## Step 3: Install Plugin

### Using lazy.nvim (Recommended)

Add to your Neovim config (`~/.config/nvim/lua/plugins/fern.lua`):

```lua
return {
  "tungsheng/fern",
  event = "VeryLazy",
  opts = {
    api = {
      provider = "anthropic",  -- or "openai", "cursor", "openai_compat"
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

### Local Development

For testing local changes:

```lua
return {
  "tungsheng/fern",
  dir = "~/path/to/fern",  -- Your local clone path
  event = "VeryLazy",
  opts = {
    api = { provider = "anthropic" }
  },
}
```

**Clone for development:**
```bash
git clone https://github.com/tungsheng/fern.git
cd fern
```

## Step 4: Restart Neovim

```bash
nvim
```

## Step 5: Verify Installation

Run health check:
```vim
:checkhealth fern
```

Expected output:
```
fern: OK

- OK Neovim version: 0.9.5
- OK curl found: curl 8.4.0
- OK Provider: anthropic
- OK ANTHROPIC_API_KEY environment variable is set
- OK API connection successful (status: 200)
- OK Plugin configuration loaded
- INFO Model: claude-sonnet-4-20250514
- INFO Timeout: 30000ms
```

## Step 6: First Use

1. Create or open a code file:
   ```vim
   :e test.lua
   ```

2. Add some code:
   ```lua
   function hello(name)
     print("Hello, " .. name)
   end
   ```

3. Enter visual mode and select the function: `V` (shift-v)

4. Press `<leader>ae` (explain selection)

5. Watch the response stream in!

**Expected Result:**
- Output pane opens on the right
- Progress spinner shows in status line
- AI explanation appears line by line
- "✓ Complete" notification when done

## Common Commands

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ae` | Visual | Explain selected code |
| `<leader>aE` | Normal | Explain entire buffer |
| `<leader>ac` | Both | Custom prompt |
| `<leader>ad` | Visual | Generate documentation |
| `<leader>ar` | Visual | Refactor suggestions |
| `<leader>af` | Visual | Fix bugs |
| `<leader>at` | Both | Toggle output pane |
| `<C-c>` | Both | Cancel request |
| `[a` | Normal | Previous response |
| `]a` | Normal | Next response |

## Quick Customization

### Change Output Position

```lua
opts = {
  ui = {
    output = {
      position = "bottom",  -- right, left, or bottom
      size = 40,  -- percentage
    }
  }
}
```

### Change Model

```lua
opts = {
  api = {
    provider = "anthropic",
    anthropic = {
      model = "claude-opus-4-20250514",
    }
  }
}
```

### Custom Keymaps

```lua
opts = {
  keymaps = {
    mappings = {
      explain_selection = "<leader>x",
      custom_prompt = "<leader>p",
    }
  }
}
```

## Troubleshooting

### "API key not found"

```bash
# Check if set (example for Anthropic)
echo $ANTHROPIC_API_KEY

# If empty, set it
export ANTHROPIC_API_KEY="your_key"

# Add to shell profile for persistence
echo 'export ANTHROPIC_API_KEY="your_key"' >> ~/.zshrc
```

### Plugin not loading

```vim
# Check plugin status
:Lazy

# Force load
:Lazy load fern

# Check for errors
:messages
```

### Output pane not showing

```vim
# Manually open
:FernToggle

# Or use command
:lua require("fern.ui.output").open()
```

### Request timeout

```lua
-- Increase timeout in config
opts = {
  api = {
    provider = "anthropic",
    anthropic = {
      timeout = 60000,  -- 60 seconds
    }
  }
}
```

## Next Steps

1. **Read the full documentation**: `README.md`
2. **Try all actions**: Test explain, document, refactor, fix
3. **Customize configuration**: Adjust to your preferences
4. **Create custom actions**: Add your own AI workflows
5. **Check keymaps reference**: `KEYMAPS.md`
6. **Run comprehensive tests**: `TESTING.md`

## Example Workflow

### Documentation Generation

```lua
-- 1. Write a function
function calculate_discount(price, percent)
  return price * (1 - percent / 100)
end

-- 2. Select it in visual mode (V)
-- 3. Press <leader>ad
-- 4. Get instant documentation:
--[[
  Calculate discounted price

  @param price number - Original price in dollars
  @param percent number - Discount percentage (0-100)
  @return number - Final price after discount

  @usage
  local final = calculate_discount(100, 20)  -- Returns 80
]]
```

### Code Explanation

```lua
-- Select complex code
-- Press <leader>ae
-- Get detailed explanation with:
--   - What the code does
--   - How it works
--   - Edge cases
--   - Potential issues
```

### Bug Fixing

```lua
-- Select problematic code
-- Press <leader>af
-- Get:
--   - Bug identification
--   - Explanation of issue
--   - Fixed version
--   - Prevention tips
```

### Custom Prompts

```lua
-- Select code or stay in buffer
-- Press <leader>ac
-- Type: "Convert this to use async/await"
-- Get custom response for your specific need
```

## Performance Tips

1. **Use selections for large files** - Faster than full buffer
2. **Cancel unwanted requests** - Press `<C-c>` to cancel
3. **Adjust timeout for slow connections** - Increase if needed
4. **Clear history periodically** - `:CursorHistoryClear`

## Support

- **Health check**: `:checkhealth fern`
- **View logs**: `~/.cache/nvim/fern.log`
- **Debug mode**: Set `log.level = "debug"` in config
- **Documentation**: See `README.md` and `doc/fern.txt`
- **Issues**: [github.com/tungsheng/fern/issues](https://github.com/tungsheng/fern/issues)

## You're Ready!

Start using AI assistance in your daily coding:

1. ✅ API key configured
2. ✅ Plugin installed
3. ✅ Health check passed
4. ✅ First request successful

Happy coding with AI! 🚀
