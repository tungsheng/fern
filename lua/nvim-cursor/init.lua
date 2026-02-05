local M = {}

M.version = "0.1.1"

local config = require("nvim-cursor.config")

function M.setup(opts)
  -- Setup configuration
  local cfg = config.setup(opts)
  
  -- Initialize logger
  require("nvim-cursor.logger").setup(cfg.log)
  
  -- Initialize history
  require("nvim-cursor.history").setup(cfg.ui.output.history)
  
  -- Initialize UI components
  require("nvim-cursor.ui.output").setup(cfg)
  
  -- Initialize keymaps (if enabled)
  if cfg.keymaps.enabled then
    require("nvim-cursor.keymaps").setup(cfg)
  end
  
  -- Create user commands
  M.create_commands()
  
  -- Log initialization
  local logger = require("nvim-cursor.logger")
  logger.info("nvim-cursor initialized", {
    version = M.version,
    model = cfg.api.cursor.model,
    log_level = cfg.log.level
  })
end

function M.create_commands()
  vim.api.nvim_create_user_command("CursorExplain", function(opts)
    require("nvim-cursor.actions").explain_selection()
  end, { range = true, desc = "Explain selected code with AI" })
  
  vim.api.nvim_create_user_command("CursorDoc", function(opts)
    require("nvim-cursor.actions").generate_doc()
  end, { range = true, desc = "Generate documentation with AI" })
  
  vim.api.nvim_create_user_command("CursorRefactor", function(opts)
    require("nvim-cursor.actions").refactor_code()
  end, { range = true, desc = "Get refactoring suggestions with AI" })
  
  vim.api.nvim_create_user_command("CursorFixBug", function(opts)
    require("nvim-cursor.actions").fix_bug()
  end, { range = true, desc = "Analyze and fix bugs with AI" })
  
  vim.api.nvim_create_user_command("CursorPrompt", function(opts)
    require("nvim-cursor.actions").custom_prompt()
  end, { range = true, desc = "Custom AI prompt" })
  
  vim.api.nvim_create_user_command("CursorToggle", function(opts)
    require("nvim-cursor.ui.output").toggle()
  end, { desc = "Toggle AI response pane" })
  
  vim.api.nvim_create_user_command("CursorHistoryClear", function(opts)
    require("nvim-cursor.history").clear()
    vim.notify("nvim-cursor: History cleared", vim.log.levels.INFO)
  end, { desc = "Clear AI response history" })
  
  vim.api.nvim_create_user_command("CursorCancel", function(opts)
    require("nvim-cursor.api.cursor").cancel_current()
  end, { desc = "Cancel current AI request" })
  
  vim.api.nvim_create_user_command("CursorVersion", function(opts)
    vim.notify("nvim-cursor version " .. M.version, vim.log.levels.INFO)
  end, { desc = "Show plugin version" })
end

return M
