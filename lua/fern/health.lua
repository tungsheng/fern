local M = {}

-- Map providers to their environment variable names
local env_vars = {
  cursor = "CURSOR_API_KEY",
  openai = "OPENAI_API_KEY",
  anthropic = "ANTHROPIC_API_KEY",
}

function M.check()
  local health = vim.health or require("health")

  health.start('fern')

  -- Check plugin version
  local ok, fern = pcall(require, 'fern')
  if ok and fern.version then
    health.info('Plugin version: ' .. fern.version)
  end

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

  -- Check plugin configuration and active provider
  local ok_config, config = pcall(require, 'fern.config')
  if ok_config and config then
    health.ok('Plugin configuration loaded')

    local opts = config.get()
    if opts and opts.api then
      local provider = opts.api.provider or "unknown"
      local provider_config = opts.api[provider] or {}

      health.info('Active provider: ' .. provider)
      health.info('Model: ' .. (provider_config.model or 'unknown'))
      health.info('Endpoint: ' .. (provider_config.endpoint or 'unknown'))
      health.info('Timeout: ' .. (provider_config.timeout or 'unknown') .. 'ms')
      health.info('Output position: ' .. (opts.ui.output.position or 'unknown'))

      -- Check API key for active provider
      local env_var = env_vars[provider]
      if env_var then
        local api_key = vim.env[env_var]
        if api_key and api_key ~= "" then
          health.ok(env_var .. ' environment variable is set')

          -- Check if API key is hardcoded in defaults (security warning)
          if config.defaults.api[provider] and type(config.defaults.api[provider].api_key) == "string" then
            health.warn(
              'API key found in config file',
              'Use environment variable instead: export ' .. env_var .. '=your_key'
            )
          end
        else
          health.error(
            env_var .. ' not set',
            {
              'Set the environment variable:',
              '  export ' .. env_var .. '=your_api_key_here',
              '',
              'Add to your shell config (~/.bashrc or ~/.zshrc):',
              '  echo \'export ' .. env_var .. '=your_key\' >> ~/.zshrc'
            }
          )
        end
      elseif provider == "openai_compat" then
        health.info('openai_compat provider: API key is optional (for local servers like Ollama)')
        local compat_key = vim.env.OPENAI_COMPAT_API_KEY
        if compat_key and compat_key ~= "" then
          health.ok('OPENAI_COMPAT_API_KEY is set')
        else
          health.info('OPENAI_COMPAT_API_KEY not set (OK for local servers)')
        end
      end

      -- Test API connection for active provider
      local endpoint = provider_config.endpoint
      if endpoint then
        health.info('Testing API connection to ' .. endpoint .. '...')

        local auth_header = ""
        if provider == "anthropic" then
          local api_key = vim.env.ANTHROPIC_API_KEY or ""
          if api_key ~= "" then
            auth_header = string.format('-H "x-api-key: %s" -H "anthropic-version: %s"', api_key, provider_config.api_version or "2023-06-01")
          end
        else
          local key_name = env_var or "OPENAI_COMPAT_API_KEY"
          local api_key = vim.env[key_name] or ""
          if api_key ~= "" then
            auth_header = string.format('-H "Authorization: Bearer %s"', api_key)
          end
        end

        local test_cmd = string.format(
          'curl -s -o /dev/null -w "%%{http_code}" -X POST %s %s -H "Content-Type: application/json" --max-time 5',
          endpoint,
          auth_header
        )

        local result = vim.fn.system(test_cmd)
        local status_code = tonumber(result)

        if status_code == 200 or status_code == 400 then
          health.ok('API connection successful (status: ' .. status_code .. ')')
        elseif status_code == 401 or status_code == 403 then
          health.error(
            'API authentication failed (status: ' .. status_code .. ')',
            'Check your API key is valid'
          )
        elseif status_code == 0 then
          health.warn(
            'Could not connect to API at ' .. endpoint,
            {
              'Check your internet connection',
              'Verify the API endpoint is accessible',
              'For local providers (Ollama), ensure the server is running'
            }
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
    end
  else
    health.error(
      'Failed to load plugin configuration',
      'Plugin may not be properly installed'
    )
  end

  -- Check log file permissions
  local log_path = vim.fn.stdpath("cache") .. "/fern.log"
  local log_dir = vim.fn.fnamemodify(log_path, ':h')

  if vim.fn.isdirectory(log_dir) == 1 then
    health.ok('Log directory exists: ' .. log_dir)

    local test_file = log_dir .. "/fern-test.tmp"
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
