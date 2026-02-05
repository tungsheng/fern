local M = {}

-- Read version from VERSION file (single source of truth)
local function read_version()
  local info = debug.getinfo(1, "S")
  local script_path = info.source:gsub("^@", "")
  local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
  local version_file = plugin_root .. "/VERSION"
  local f = io.open(version_file, "r")
  if f then
    local v = f:read("*l")
    f:close()
    if v then return vim.trim(v) end
  end
  return "0.2.0"
end

M.version = read_version()

local config = require("fern.config")

function M.setup(opts)
  -- Setup configuration
  local cfg = config.setup(opts)

  -- Initialize logger
  require("fern.logger").setup(cfg.log)

  -- Initialize history
  require("fern.history").setup(cfg.ui.output.history)

  -- Initialize UI components
  require("fern.ui.output").setup(cfg)

  -- Initialize keymaps (if enabled)
  if cfg.keymaps.enabled then
    require("fern.keymaps").setup(cfg)
  end

  -- Create user commands
  M.create_commands()

  -- Log initialization
  local logger = require("fern.logger")
  local provider = cfg.api.provider
  local provider_config = cfg.api[provider] or {}
  logger.info("fern initialized", {
    version = M.version,
    provider = provider,
    model = provider_config.model,
    log_level = cfg.log.level
  })
end

function M.create_commands()
  vim.api.nvim_create_user_command("FernExplain", function(opts)
    require("fern.actions").explain_selection()
  end, { range = true, desc = "Explain selected code with AI" })

  vim.api.nvim_create_user_command("FernDoc", function(opts)
    require("fern.actions").generate_doc()
  end, { range = true, desc = "Generate documentation with AI" })

  vim.api.nvim_create_user_command("FernRefactor", function(opts)
    require("fern.actions").refactor_code()
  end, { range = true, desc = "Get refactoring suggestions with AI" })

  vim.api.nvim_create_user_command("FernFixBug", function(opts)
    require("fern.actions").fix_bug()
  end, { range = true, desc = "Analyze and fix bugs with AI" })

  vim.api.nvim_create_user_command("FernPrompt", function(opts)
    require("fern.actions").custom_prompt()
  end, { range = true, desc = "Custom AI prompt" })

  vim.api.nvim_create_user_command("FernToggle", function(opts)
    require("fern.ui.output").toggle()
  end, { desc = "Toggle AI response pane" })

  vim.api.nvim_create_user_command("FernHistoryClear", function(opts)
    require("fern.history").clear()
    vim.notify("fern: History cleared", vim.log.levels.INFO)
  end, { desc = "Clear AI response history" })

  vim.api.nvim_create_user_command("FernCancel", function(opts)
    require("fern.api.client").cancel_current()
  end, { desc = "Cancel current AI request" })

  vim.api.nvim_create_user_command("FernVersion", function(opts)
    vim.notify("fern version " .. M.version, vim.log.levels.INFO)
  end, { desc = "Show plugin version" })
end

return M
