local M = {}

function M.check()
  local health = vim.health or require("health")
  
  health.start('nvim-cursor')
  
  -- Check Neovim version
  local version = vim.version()
  if version.major > 0 or version.minor >= 9 then
    health.ok(string.format('Neovim version: %d.%d.%d', version.major, version.minor, version.patch))
  else
    health.error(
      string.format('Neovim 0.9+ required. Current: %d.%d.%d', version.major, version.minor, version.patch),
      'Please upgrade Neovim to version 0.9 or higher'
    )
  end
  
  -- Check curl
  if vim.fn.executable('curl') == 1 then
    local curl_version = vim.fn.system('curl --version 2>&1 | head -n 1')
    health.ok('curl found: ' .. curl_version:gsub('\n', ''))
  else
    health.error(
      'curl not found in PATH',
      {
        'Install curl:',
        '  macOS: brew install curl',
        '  Ubuntu/Debian: sudo apt install curl',
        '  Fedora: sudo dnf install curl'
      }
    )
  end
  
  -- Check API key
  local api_key = vim.env.CURSOR_API_KEY
  
  if api_key and api_key ~= "" then
    health.ok('CURSOR_API_KEY environment variable is set')
    
    -- Check if API key is in config (security warning)
    local config = require('nvim-cursor.config')
    if config.defaults.api.cursor.api_key and type(config.defaults.api.cursor.api_key) == "string" then
      health.warn(
        'API key found in config file',
        'Use environment variable instead: export CURSOR_API_KEY=your_key'
      )
    end
  else
    health.error(
      'CURSOR_API_KEY not set',
      {
        'Set the environment variable:',
        '  export CURSOR_API_KEY=your_api_key_here',
        '',
        'Add to your shell config (~/.bashrc or ~/.zshrc):',
        '  echo \'export CURSOR_API_KEY=your_key\' >> ~/.zshrc'
      }
    )
  end
  
  -- Check log file permissions
  local log_path = vim.fn.stdpath("cache") .. "/nvim-cursor.log"
  local log_dir = vim.fn.fnamemodify(log_path, ':h')
  
  if vim.fn.isdirectory(log_dir) == 1 then
    health.ok('Log directory exists: ' .. log_dir)
    
    -- Check if we can write to the log file
    local test_file = log_dir .. "/nvim-cursor-test.tmp"
    local f = io.open(test_file, 'w')
    if f then
      f:write('test')
      f:close()
      vim.fn.delete(test_file)
      health.ok('Log directory is writable')
    else
      health.warn(
        'Cannot write to log directory: ' .. log_dir,
        'Check directory permissions'
      )
    end
  else
    health.info('Log directory will be created on first use: ' .. log_dir)
  end
  
  -- Test API connection (if API key is available)
  if api_key and api_key ~= "" then
    health.info('Testing API connection...')
    
    local test_cmd = string.format(
      'curl -s -o /dev/null -w "%%{http_code}" -X POST https://api.cursor.sh/v1/chat/completions -H "Authorization: Bearer %s" -H "Content-Type: application/json" --max-time 5',
      api_key
    )
    
    local result = vim.fn.system(test_cmd)
    local status_code = tonumber(result)
    
    if status_code == 200 or status_code == 400 then
      -- 400 is ok here - it means API is reachable and key is valid (just bad request body)
      health.ok('API connection successful (status: ' .. status_code .. ')')
    elseif status_code == 401 or status_code == 403 then
      health.error(
        'API authentication failed (status: ' .. status_code .. ')',
        'Check your CURSOR_API_KEY is valid'
      )
    elseif status_code then
      health.warn(
        'API returned unexpected status: ' .. status_code,
        'API may be experiencing issues'
      )
    else
      health.warn(
        'Could not connect to API',
        {
          'Check your internet connection',
          'Verify API endpoint is accessible',
          'Check firewall settings'
        }
      )
    end
  end
  
  -- Check plugin configuration
  local ok, config = pcall(require, 'nvim-cursor.config')
  if ok and config then
    health.ok('Plugin configuration loaded')
    
    local opts = config.get()
    if opts then
      health.info('Model: ' .. (opts.api.cursor.model or 'unknown'))
      health.info('Timeout: ' .. (opts.api.cursor.timeout or 'unknown') .. 'ms')
      health.info('Output position: ' .. (opts.ui.output.position or 'unknown'))
    end
  else
    health.error(
      'Failed to load plugin configuration',
      'Plugin may not be properly installed'
    )
  end
  
  -- Check optional dependencies
  health.start('Optional dependencies')
  
  local has_notify = pcall(require, 'notify')
  if has_notify then
    health.ok('nvim-notify found (enhanced notifications)')
  else
    health.info('nvim-notify not found (using default notifications)')
  end
  
  local has_telescope = pcall(require, 'telescope')
  if has_telescope then
    health.ok('telescope.nvim found (enhanced UI)')
  else
    health.info('telescope.nvim not found (using default UI)')
  end
end

return M
