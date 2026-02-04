local M = {}

local config = require("nnvim-cursor.config")

function M.setup(opts)
  -- Setup configuration
  local cfg = config.setup(opts)
  
  -- Initialize logger
  require("nnvim-cursor.logger").setup(cfg.log)
  
  -- Initialize history
  require("nnvim-cursor.history").setup(cfg.ui.output.history)
  
  -- Initialize UI components
  require("nnvim-cursor.ui.output").setup(cfg)
  
  -- Initialize keymaps (if enabled)
  if cfg.keymaps.enabled then
    require("nnvim-cursor.keymaps").setup(cfg)
  end
  
  -- Create user commands
  M.create_commands()
  
  -- Log initialization
  local logger = require("nnvim-cursor.logger")
  logger.info("nnvim-cursor initialized", {
    model = cfg.api.cursor.model,
    log_level = cfg.log.level
  })
end

function M.create_commands()
  vim.api.nvim_create_user_command("CursorExplain", function(opts)
    require("nnvim-cursor.actions").explain_selection()
  end, { range = true, desc = "Explain selected code with AI" })
  
  vim.api.nvim_create_user_command("CursorDoc", function(opts)
    require("nnvim-cursor.actions").generate_doc()
  end, { range = true, desc = "Generate documentation with AI" })
  
  vim.api.nvim_create_user_command("CursorRefactor", function(opts)
    require("nnvim-cursor.actions").refactor_code()
  end, { range = true, desc = "Get refactoring suggestions with AI" })
  
  vim.api.nvim_create_user_command("CursorFixBug", function(opts)
    require("nnvim-cursor.actions").fix_bug()
  end, { range = true, desc = "Analyze and fix bugs with AI" })
  
  vim.api.nvim_create_user_command("CursorPrompt", function(opts)
    require("nnvim-cursor.actions").custom_prompt()
  end, { range = true, desc = "Custom AI prompt" })
  
  vim.api.nvim_create_user_command("CursorToggle", function(opts)
    require("nnvim-cursor.ui.output").toggle()
  end, { desc = "Toggle AI response pane" })
  
  vim.api.nvim_create_user_command("CursorHistoryClear", function(opts)
    require("nnvim-cursor.history").clear()
    vim.notify("nnvim-cursor: History cleared", vim.log.levels.INFO)
  end, { desc = "Clear AI response history" })
  
  vim.api.nvim_create_user_command("CursorCancel", function(opts)
    require("nnvim-cursor.api.cursor").cancel_current()
  end, { desc = "Cancel current AI request" })
end

return M
