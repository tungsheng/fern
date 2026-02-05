# Testing Guide for fern

This guide helps you test the fern plugin after installation.

**Repository:** [github.com/tungsheng/fern](https://github.com/tungsheng/fern)

## Prerequisites

1. **Set API Key**
   ```bash
   # For your chosen provider:
   export ANTHROPIC_API_KEY="your_api_key_here"
   # or: export OPENAI_API_KEY="your_api_key_here"
   # or: export CURSOR_API_KEY="your_api_key_here"
   ```

   Verify it's set:
   ```bash
   echo $ANTHROPIC_API_KEY  # or your provider's key
   ```

2. **Install the Plugin**
   Add to your Neovim config (lazy.nvim example):
   ```lua
   {
     "tungsheng/fern",
     dir = "~/path/to/fern",  -- Use local path for testing
     event = "VeryLazy",
     opts = {
       api = { provider = "anthropic" }  -- or your chosen provider
     },
   }
   ```

   Or clone from GitHub:
   ```bash
   git clone https://github.com/tungsheng/fern.git
   ```

## Step 1: Health Check

Run the built-in health check to verify everything is configured correctly:

```vim
:checkhealth fern
```

Expected output should show:
- ✓ Neovim version 0.9+
- ✓ curl found
- ✓ API key is set for active provider
- ✓ API connection successful (if internet available)
- ✓ Plugin configuration loaded
- ✓ Log directory exists

## Step 2: Module Loading Test

Open the test file:
```vim
:e test-manual.lua
```

Source it to run the tests:
```vim
:luafile %
```

This will test:
- Module loading
- Config initialization
- Logger functionality
- Error handling
- Progress indicators
- History management
- Context extraction

## Step 3: Interactive Testing

Open the example file:
```vim
:e example.lua
```

### Test 1: Explain Code

1. Enter visual mode: `V`
2. Select the `calculate_factorial` function
3. Press `<leader>ae`
4. Watch the output pane open on the right
5. See the AI response stream in real-time

**Expected behavior:**
- Output pane opens automatically
- Progress spinner shows in status line
- Response appears incrementally
- "✓ Complete" notification when done

### Test 2: Generate Documentation

1. Select the `User:new` method in visual mode
2. Press `<leader>ad`
3. Check the generated documentation format

**Expected behavior:**
- Comprehensive docstring with parameters
- Return value description
- Usage examples

### Test 3: Refactor Code

1. Select the `validate_user_input` function
2. Press `<leader>ar`
3. Review refactoring suggestions

**Expected behavior:**
- Identifies code smells
- Suggests improvements
- Explains reasoning

### Test 4: Fix Bug

1. Select the `process_data` function (has a bug)
2. Press `<leader>af`
3. Check if AI identifies the issue

**Expected behavior:**
- Identifies the sparse array issue
- Suggests fix
- Explains why it's a bug

### Test 5: Custom Prompt

1. Select any code or stay in normal mode
2. Press `<leader>ac`
3. Type: "Add error handling to this code"
4. Press Enter
5. Watch the custom response

**Expected behavior:**
- Floating input window appears
- Can type multi-line prompts
- ESC cancels, Enter submits
- Response addresses your specific request

### Test 6: Full Buffer Analysis

1. In normal mode (no selection)
2. Press `<leader>aE`
3. Check that entire buffer is analyzed

**Expected behavior:**
- Analyzes all code in file
- Provides overview
- Identifies patterns

## Step 4: Feature Testing

### Toggle Output Pane

- Press `<leader>at` to hide output
- Press `<leader>at` again to show
- Content should be preserved

### Cancel Request

1. Start a request (e.g., `<leader>ae`)
2. Immediately press `<C-c>`
3. Request should be cancelled

**Expected behavior:**
- Progress spinner stops
- "Request cancelled" notification
- Can start new request

### Response History

After making several requests:

1. Press `]a` to go to next response in history
2. Press `[a` to go to previous response
3. Status shows "History: 2/5" (example)

**Expected behavior:**
- Can navigate through past responses
- Current index is displayed
- Content switches between responses

### Clear History

```vim
:FernHistoryClear
```

**Expected behavior:**
- "History cleared" notification
- Previous responses removed

## Step 5: Error Handling Tests

### Test API Key Error

1. Temporarily unset API key:
   ```bash
   unset ANTHROPIC_API_KEY  # or your provider's key
   ```
2. Restart Neovim
3. Try any action
4. Should see clear error message with instructions

### Test Network Error

1. Disable internet connection
2. Try any action
3. Should see network error with retry attempts
4. After max retries, clear error message

### Test Rate Limiting

If you hit rate limits:
- Should see "Rate limit exceeded" message
- Plugin automatically retries with backoff
- Eventually succeeds or shows final error

## Step 6: Logging Tests

### Enable Debug Logging

Add to your config:
```lua
opts = {
  log = {
    level = "debug",
    use_file = true
  }
}
```

### View Logs

```bash
tail -f ~/.cache/nvim/fern.log
```

**Expected behavior:**
- Requests are logged
- Sensitive data (API keys) is redacted
- Errors are logged with context
- Timestamps are included

## Step 7: Configuration Tests

### Test Custom Configuration

```lua
require("fern").setup({
  api = {
    provider = "anthropic",
    anthropic = {
      model = "claude-sonnet-4-20250514",
      timeout = 60000,  -- Increase timeout
    }
  },
  ui = {
    output = {
      position = "bottom",  -- Change position
      size = 30,
    }
  },
})
```

**Expected behavior:**
- Output appears at bottom
- Takes 30% of screen height
- Uses specified model
- Has longer timeout

### Test Custom Keymaps

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

**Expected behavior:**
- New keymaps work
- Old keymaps disabled

### Test Disabled Keymaps

```lua
opts = {
  keymaps = {
    enabled = false
  }
}
```

**Expected behavior:**
- No default keymaps registered
- Can define your own manually

## Step 8: Performance Tests

### Large File Test

1. Open a file with 1000+ lines
2. Try `<leader>aE` (explain buffer)
3. Should see warning about large buffer
4. Response should still work

### Rapid Requests

1. Make a request (`<leader>ae`)
2. Immediately make another request
3. First should be cancelled
4. Second should proceed

**Expected behavior:**
- Only one request active at a time
- Previous cancelled automatically
- No memory leaks

## Troubleshooting

### Plugin Not Loading

Check Lazy loading:
```vim
:Lazy
```

Find fern in the list. If not loaded, try:
```vim
:Lazy load fern
```

### Commands Not Available

Check if plugin initialized:
```vim
:lua =require("fern")
```

Should return a table, not an error.

### Keymaps Not Working

Check if keymaps are registered:
```vim
:map <leader>ae
```

Should show the mapping. If not:
- Check `keymaps.enabled` in config
- Check for keymap conflicts

### Output Pane Issues

If pane doesn't appear:
```vim
:lua require("fern.ui.output").open()
```

Check for errors in `:messages`.

### API Connection Issues

Test curl directly:
```bash
curl -X POST https://api.cursor.sh/v1/chat/completions \
  -H "Authorization: Bearer $CURSOR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4","messages":[{"role":"user","content":"test"}],"stream":false}'
```

Should return a JSON response.

## Success Criteria

All tests passing means:

✅ Health check passes  
✅ Modules load without errors  
✅ All actions work (explain, doc, refactor, fix)  
✅ Custom prompts work  
✅ History navigation works  
✅ Request cancellation works  
✅ Output pane toggles correctly  
✅ Progress indicators show  
✅ Errors are handled gracefully  
✅ Retry logic works  
✅ Logging works (in debug mode)  
✅ Configuration changes apply  

## Next Steps

After testing:

1. **Customize Configuration** - Adjust keymaps, prompts, UI to your preference
2. **Add Custom Actions** - Create your own AI actions
3. **Integrate with Workflow** - Use in daily coding
4. **Report Issues** - File bugs or feature requests at [github.com/tungsheng/fern/issues](https://github.com/tungsheng/fern/issues)
5. **Contribute** - Submit PRs for improvements at [github.com/tungsheng/fern](https://github.com/tungsheng/fern)

## Automated Testing (Future)

To add automated tests:

1. Create `tests/` directory
2. Use `plenary.nvim` test framework
3. Add CI/CD with GitHub Actions
4. Test all modules independently
5. Integration tests with mock API

Example test structure:
```
tests/
├── config_spec.lua
├── context_spec.lua
├── history_spec.lua
├── errors_spec.lua
└── integration_spec.lua
```
