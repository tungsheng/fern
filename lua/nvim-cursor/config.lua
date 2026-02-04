local M = {}

M.defaults = {
  api = {
    provider = "cursor",
    cursor = {
      endpoint = "https://api.cursor.sh/v1/chat/completions",
      api_key = nil,  -- MUST use env: CURSOR_API_KEY
      model = "gpt-4",
      timeout = 30000,
      max_retries = 3,
      retry_delay = 1000  -- milliseconds, exponential backoff
    },
  },
  
  ui = {
    input = {
      width = 80,
      height = 10,
      border = "rounded",
      title = " Cursor AI Prompt ",
      title_pos = "center"
    },
    output = {
      position = "right", -- right, bottom, left
      size = 50, -- percentage
      border = "rounded",
      title = " Cursor AI Response ",
      filetype = "markdown",
      max_lines = 10000,  -- Prevent memory issues
      max_line_length = 500,  -- Truncate very long lines
      auto_scroll = true,
      preserve_on_close = true,  -- Keep content when toggling
      show_progress = true,
      
      -- Response history navigation
      history = {
        enabled = true,
        max_entries = 50,
        keymaps = {
          next = "]a",  -- Next response in history
          prev = "[a",  -- Previous response
          clear = "<leader>aC"  -- Clear history
        }
      }
    },
  },
  
  keymaps = {
    enabled = true,  -- Set false to disable defaults
    mappings = {
      toggle_output = "<leader>at",
      cancel_request = "<C-c>",  -- Cancel streaming request
      custom_prompt = "<leader>ac",
      explain_selection = "<leader>ae",
      explain_buffer = "<leader>aE",
      generate_doc = "<leader>ad",
      refactor_code = "<leader>ar",
      fix_bug = "<leader>af"
    }
  },
  
  -- Context extraction settings
  context = {
    include_line_numbers = true,
    include_file_path = true,
    include_filetype = true,
    surrounding_lines = 5,  -- Lines before/after selection
    max_buffer_lines = 5000  -- Warn if buffer exceeds this
  },
  
  actions = {
    explain = {
      system_prompt = "Explain the following code in detail, including purpose, logic, and any edge cases:",
      temperature = 0.3,
      show_diff = false
    },
    doc = {
      system_prompt = "Generate comprehensive documentation for the following code, including function/class descriptions, parameters, return values, and usage examples:",
      temperature = 0.2,
      show_diff = false
    },
    refactor = {
      system_prompt = "Suggest refactoring improvements for the following code, focusing on readability, performance, and best practices:",
      temperature = 0.4,
      show_diff = true  -- Show diff for refactoring
    },
    fix_bug = {
      system_prompt = "Analyze this code for bugs and provide fixes with explanations:",
      temperature = 0.3,
      show_diff = true
    }
  },
  
  -- Custom actions - user can extend without forking
  custom_actions = {
    -- Example:
    -- add_tests = {
    --   keymap = "<leader>aT",
    --   mode = "v",
    --   system_prompt = "Generate comprehensive unit tests for this code:",
    --   temperature = 0.4
    -- }
  },
  
  -- Logging configuration
  log = {
    level = "warn",  -- debug, info, warn, error
    use_console = false,
    use_file = true,
    path = vim.fn.stdpath("cache") .. "/nvim-cursor.log",
    redact_logs = true  -- Redact sensitive data from logs
  },
  
  -- Security settings
  security = {
    warn_api_key_in_config = true,  -- Warn if API key in lua config
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  
  -- Security validation
  M.validate_security()
  
  return M.options
end

function M.validate_security()
  -- Warn if API key is hardcoded in config
  if type(M.options.api.cursor.api_key) == "string" and M.options.security.warn_api_key_in_config then
    vim.notify(
      "WARNING: API key found in config file. Use environment variable CURSOR_API_KEY instead.",
      vim.log.levels.WARN
    )
  end
  
  -- Get API key from env if not in config
  if not M.options.api.cursor.api_key then
    M.options.api.cursor.api_key = vim.env.CURSOR_API_KEY
  end
  
  -- Ensure API key exists
  if not M.options.api.cursor.api_key then
    vim.notify(
      "nvim-cursor: No API key found. Set CURSOR_API_KEY environment variable.\nRun :checkhealth nvim-cursor for help.",
      vim.log.levels.ERROR
    )
    return false
  end
  
  return true
end

function M.get()
  return M.options
end

return M
