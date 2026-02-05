# fern Keymaps Reference

Complete reference for all default keymaps and their usage.

## Default Keymaps

| Keymap | Mode | Action | Description |
|--------|------|--------|-------------|
| `<leader>ae` | Visual | Explain Selection | Explain the selected code in detail |
| `<leader>aE` | Normal | Explain Buffer | Explain the entire buffer content |
| `<leader>ad` | Visual | Generate Docs | Generate documentation for selected code |
| `<leader>ar` | Visual | Refactor Code | Get refactoring suggestions for selected code |
| `<leader>ac` | Normal/Visual | Custom Prompt | Open floating input for custom AI prompt |
| `<leader>at` | Normal/Visual | Toggle Output | Show/hide the AI response pane |

## Keymap Details

### Explain Selection (`<leader>ae`)

**Mode**: Visual (v, V, or Ctrl-V)

**Usage**:
1. Select code in visual mode
2. Press `<leader>ae`
3. Response appears in split pane

**Example**:
```lua
-- Select this function and press <leader>ae
function calculate_total(items)
  local sum = 0
  for _, item in ipairs(items) do
    sum = sum + item.price
  end
  return sum
end
```

**AI Response Includes**:
- Purpose of the code
- Logic explanation
- Edge cases
- Potential issues

---

### Explain Buffer (`<leader>aE`)

**Mode**: Normal

**Usage**:
1. Open any file
2. Press `<leader>aE` (capital E)
3. AI analyzes entire buffer

**Best For**:
- Understanding new codebases
- Getting overview of a module
- Learning unfamiliar code patterns

---

### Generate Documentation (`<leader>ad`)

**Mode**: Visual

**Usage**:
1. Select function/class/module
2. Press `<leader>ad`
3. Receive formatted documentation

**Example Output**:
````markdown
## Function: calculate_total

Calculates the sum of prices from a list of items.

### Parameters
- `items` (table): Array of item objects with price property

### Returns
- (number): Total sum of all item prices

### Example
```lua
local items = {{price = 10}, {price = 20}}
local total = calculate_total(items)  -- Returns 30
```
````

---

### Refactor Code (`<leader>ar`)

**Mode**: Visual

**Usage**:
1. Select code that needs improvement
2. Press `<leader>ar`
3. Receive refactoring suggestions

**Suggestions Include**:
- Performance improvements
- Readability enhancements
- Best practice recommendations
- Modern language features

---

### Custom Prompt (`<leader>ac`)

**Mode**: Normal or Visual

**Usage**:
1. Optionally select code (visual mode)
2. Press `<leader>ac`
3. Floating window appears
4. Type your prompt
5. Press Enter (normal mode) or Ctrl-Enter (insert mode)

**Example Prompts**:
- "Add error handling to this function"
- "Convert this to use async/await"
- "Explain the time complexity"
- "Write unit tests for this code"
- "What design pattern is this?"

**Input Window Controls**:
- `Enter` (normal mode): Submit prompt
- `Ctrl-Enter` (insert mode): Submit prompt
- `Esc` or `q`: Cancel

---

### Toggle Output (`<leader>at`)

**Mode**: Normal or Visual

**Usage**:
- Press `<leader>at` to show/hide the response pane
- Useful for clearing screen space
- Pane remembers content when hidden

**Output Pane Controls**:
- `q` or `Esc`: Close the pane
- Content persists across toggles

---

## Context Behavior

### Visual Mode Actions
When you use keymaps in visual mode (`<leader>ae`, `<leader>ad`, `<leader>ar`):
- Only selected text is sent to AI
- File path and language included automatically
- Selection marked as "Selected code"

### Normal Mode Actions
When you use keymaps in normal mode (`<leader>aE`, `<leader>ac` without selection):
- Entire buffer content is sent to AI
- File path and language included automatically
- Context marked as "Full buffer"

### Automatic Context
All requests automatically include:
```
File: src/utils/helpers.lua
Language: lua
Context: Selected code / Full buffer

Code:
```lua
[your code here]
```
```

---

## Customizing Keymaps

Override default keymaps in your configuration:

```lua
require("fern").setup({
  keymaps = {
    toggle_output = "<leader>ao",      -- Change from <leader>at
    custom_prompt = "<leader>ap",       -- Change from <leader>ac
    explain_selection = "<leader>ax",   -- Change from <leader>ae
    explain_buffer = "<leader>aX",      -- Change from <leader>aE
    generate_doc = "<leader>ad",        -- Keep default
    refactor_code = "<leader>ar",       -- Keep default
  },
})
```

### Disable Default Keymaps

Set keymaps to empty string to disable:

```lua
require("fern").setup({
  keymaps = {
    refactor_code = "", -- Disables <leader>ar
  },
})
```

Then map manually:

```lua
vim.keymap.set("v", "<leader>rf", function()
  require("fern.actions").refactor_code()
end, { desc = "Refactor with AI" })
```

---

## Integration Tips

### Which-Key Integration

If you use [which-key.nvim](https://github.com/folke/which-key.nvim):

```lua
local wk = require("which-key")
wk.register({
  ["<leader>a"] = {
    name = "AI Assistant",
    e = "Explain selection",
    E = "Explain buffer",
    d = "Generate docs",
    r = "Refactor code",
    c = "Custom prompt",
    t = "Toggle output",
  },
}, { mode = "v" })
```

### LazyVim Integration

LazyVim users get automatic integration with the `keys` spec:

```lua
{
  "yourtungsheng/fern",
  keys = {
    { "<leader>ae", mode = "v", desc = "AI: Explain selection" },
    { "<leader>aE", mode = "n", desc = "AI: Explain buffer" },
    -- ... etc
  }
}
```

Keys are lazy-loaded and appear in LazyVim's keymap UI automatically.

---

## Workflow Examples

### Code Review Workflow

1. Open a file to review
2. Press `<leader>aE` to get overview
3. Select specific functions and press `<leader>ae` for details
4. Press `<leader>at` to toggle output as needed

### Documentation Workflow

1. Select function/class definition
2. Press `<leader>ad` to generate docs
3. Copy output from response pane
4. Paste into your code as comments

### Refactoring Workflow

1. Select code that needs improvement
2. Press `<leader>ar` for suggestions
3. Review recommendations
4. Implement changes
5. Select again and press `<leader>ae` to verify improvements

### Learning Workflow

1. Open unfamiliar codebase
2. Press `<leader>aE` for file overview
3. Select complex sections
4. Press `<leader>ac` and ask specific questions:
   - "What design pattern is this?"
   - "Why is this implemented this way?"
   - "What are the trade-offs here?"

---

## Command Alternatives

All keymaps have corresponding Ex commands:

| Keymap | Command | Equivalent |
|--------|---------|------------|
| `<leader>ae` | `:FernExplain` | Explain selection |
| `<leader>ad` | `:FernDoc` | Generate docs |
| `<leader>ar` | `:FernRefactor` | Refactor suggestions |
| `<leader>ac` | `:FernPrompt` | Custom prompt |
| `<leader>at` | `:FernToggle` | Toggle output |

Use commands for:
- Scripting and automation
- Custom mappings
- Testing and debugging

---

## Troubleshooting Keymaps

### Keymap Not Working

1. Check for conflicts:
```vim
:verbose map <leader>ae
```

2. Verify plugin loaded:
```vim
:echo g:loaded_vim_cursor
" Should output: 1
```

3. Check keymap exists:
```vim
:map <leader>ae
" Should show the mapping
```

### Wrong Mode

Some actions only work in specific modes:
- `<leader>ae`, `<leader>ad`, `<leader>ar`: Visual mode only
- `<leader>aE`: Normal mode only
- `<leader>ac`, `<leader>at`: Normal or Visual mode

### Leader Key

Default `<leader>` is `\`. Check your leader:
```lua
-- In init.lua
vim.g.mapleader = " " -- Space as leader (common)
```

If leader is space, keymaps become:
- `Space + a + e` for explain selection
- `Space + a + t` for toggle output
- etc.
