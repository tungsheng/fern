-- Manual test script for fern
-- Run with: nvim --cmd "luafile test-manual.lua"

print("=== fern Manual Test Suite ===\n")

-- Test 1: Check if module can be loaded
print("1. Testing module loading...")
local ok, fern = pcall(require, "fern")
if ok then
  print("  ✓ fern module loaded")
else
  print("  ✗ Failed to load fern: " .. tostring(fern))
  return
end

-- Test 2: Check config module
print("\n2. Testing config module...")
local ok_config, config = pcall(require, "fern.config")
if ok_config then
  print("  ✓ Config module loaded")

  -- Setup with defaults
  config.setup({})
  local opts = config.get()

  if opts then
    print("  ✓ Config initialized")
    print("    Provider: " .. opts.api.provider)
    local provider_config = opts.api[opts.api.provider] or {}
    print("    Model: " .. (provider_config.model or "unknown"))
    print("    Timeout: " .. (provider_config.timeout or "unknown"))
  else
    print("  ✗ Config not initialized")
  end
else
  print("  ✗ Failed to load config: " .. tostring(config))
end

-- Test 3: Check logger module
print("\n3. Testing logger module...")
local ok_logger, logger = pcall(require, "fern.logger")
if ok_logger then
  print("  ✓ Logger module loaded")

  logger.setup({ level = "debug", use_console = true, use_file = false })
  logger.info("Test log message", { test = true })
  print("  ✓ Logger can write messages")
else
  print("  ✗ Failed to load logger: " .. tostring(logger))
end

-- Test 4: Check error handling module
print("\n4. Testing errors module...")
local ok_errors, errors = pcall(require, "fern.api.errors")
if ok_errors then
  print("  ✓ Errors module loaded")

  local err = errors.new('NETWORK', 'Test error')
  print("  ✓ Can create error objects")
  print("    Type: " .. err.type)
  print("    Message: " .. err.message)
  print("    Retry: " .. tostring(err.retry))

  local formatted = errors.format_for_user(err)
  print("  ✓ Can format errors for users")
else
  print("  ✗ Failed to load errors: " .. tostring(errors))
end

-- Test 5: Check progress module
print("\n5. Testing progress module...")
local ok_progress, progress = pcall(require, "fern.ui.progress")
if ok_progress then
  print("  ✓ Progress module loaded")
else
  print("  ✗ Failed to load progress: " .. tostring(progress))
end

-- Test 6: Check history module
print("\n6. Testing history module...")
local ok_history, history = pcall(require, "fern.history")
if ok_history then
  print("  ✓ History module loaded")

  history.setup({ max_entries = 50 })
  history.add_entry({ prompt = "test" }, "response")

  if history.get_count() == 1 then
    print("  ✓ Can add and retrieve history entries")
  else
    print("  ✗ History count mismatch")
  end

  history.clear()
  if history.get_count() == 0 then
    print("  ✓ Can clear history")
  else
    print("  ✗ History clear failed")
  end
else
  print("  ✗ Failed to load history: " .. tostring(history))
end

-- Test 7: Check health module
print("\n7. Testing health module...")
local ok_health, health = pcall(require, "fern.health")
if ok_health then
  print("  ✓ Health module loaded")
  print("  ℹ Run :checkhealth fern to see full diagnostics")
else
  print("  ✗ Failed to load health: " .. tostring(health))
end

-- Test 8: Check context module
print("\n8. Testing context module...")
local ok_context, context = pcall(require, "fern.context")
if ok_context then
  print("  ✓ Context module loaded")

  local info = context.get_buffer_info()
  if info then
    print("  ✓ Can get buffer info")
    print("    Filepath: " .. (info.filepath or "none"))
    print("    Filetype: " .. (info.filetype or "none"))
  end
else
  print("  ✗ Failed to load context: " .. tostring(context))
end

-- Test 9: Check API key for active provider
print("\n9. Testing API key configuration...")
local test_config = require("fern.config")
local test_opts = test_config.get()
local provider = test_opts and test_opts.api.provider or "cursor"
local env_vars = { cursor = "CURSOR_API_KEY", openai = "OPENAI_API_KEY", anthropic = "ANTHROPIC_API_KEY" }
local env_var = env_vars[provider]
if env_var then
  local api_key = vim.env[env_var]
  if api_key and api_key ~= "" then
    print("  ✓ " .. env_var .. " environment variable is set")
    print("    Length: " .. #api_key .. " characters")
  else
    print("  ⚠ " .. env_var .. " not set")
    print("    Set with: export " .. env_var .. "=your_key")
  end
else
  print("  ℹ Provider '" .. provider .. "' may not require an API key")
end

-- Test 10: Check curl availability
print("\n10. Testing curl availability...")
if vim.fn.executable('curl') == 1 then
  print("  ✓ curl is available")
  local version = vim.fn.system('curl --version 2>&1 | head -n 1')
  print("    " .. version:gsub('\n', ''))
else
  print("  ✗ curl not found in PATH")
end

print("\n=== Test Summary ===")
print("All basic module tests completed.")
print("\nNext steps:")
print("1. Set API key for your provider if not already set")
print("2. Run :checkhealth fern in Neovim")
print("3. Try the plugin with <leader>ae on selected code")
print("\nFor detailed diagnostics, run:")
print("  :checkhealth fern")
