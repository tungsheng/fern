local M = {}

function M.setup(config)
  if not config.keymaps.enabled then
    return
  end
  
  local mappings = config.keymaps.mappings
  local actions = require("nvim-cursor.actions")
  local output = require("nvim-cursor.ui.output")
  local cursor_api = require("nvim-cursor.api.cursor")
  
  -- Toggle output pane (works in any mode)
  if mappings.toggle_output then
    vim.keymap.set({ "n", "v" }, mappings.toggle_output, function()
      output.toggle()
    end, { desc = "AI: Toggle output pane", silent = true })
  end
  
  -- Cancel current request
  if mappings.cancel_request then
    vim.keymap.set({ "n", "v" }, mappings.cancel_request, function()
      cursor_api.cancel_current()
    end, { desc = "AI: Cancel request", silent = true })
  end
  
  -- Custom prompt (works in normal and visual mode)
  if mappings.custom_prompt then
    vim.keymap.set({ "n", "v" }, mappings.custom_prompt, function()
      actions.custom_prompt()
    end, { desc = "AI: Custom prompt", silent = true })
  end
  
  -- Explain selection (visual mode only)
  if mappings.explain_selection then
    vim.keymap.set("v", mappings.explain_selection, function()
      actions.explain_selection()
    end, { desc = "AI: Explain selection", silent = true })
  end
  
  -- Explain buffer (normal mode only)
  if mappings.explain_buffer then
    vim.keymap.set("n", mappings.explain_buffer, function()
      actions.explain_buffer()
    end, { desc = "AI: Explain buffer", silent = true })
  end
  
  -- Generate documentation (visual mode only)
  if mappings.generate_doc then
    vim.keymap.set("v", mappings.generate_doc, function()
      actions.generate_doc()
    end, { desc = "AI: Generate docs", silent = true })
  end
  
  -- Refactor code (visual mode only)
  if mappings.refactor_code then
    vim.keymap.set("v", mappings.refactor_code, function()
      actions.refactor_code()
    end, { desc = "AI: Refactor code", silent = true })
  end
  
  -- Fix bug (visual mode only)
  if mappings.fix_bug then
    vim.keymap.set("v", mappings.fix_bug, function()
      actions.fix_bug()
    end, { desc = "AI: Fix bug", silent = true })
  end
  
  -- Register custom action keymaps
  if config.custom_actions then
    for name, action_config in pairs(config.custom_actions) do
      if action_config.keymap then
        vim.keymap.set(
          action_config.mode or 'v',
          action_config.keymap,
          function()
            -- Execute custom action
            local action_def = {
              system_prompt = action_config.system_prompt,
              temperature = action_config.temperature or 0.7,
              show_diff = action_config.show_diff or false
            }
            
            local mode_str = (action_config.mode == 'n') and 'buffer' or 'selection'
            local execute = require("nvim-cursor.actions")
            -- We need to expose execute_action or create custom actions dynamically
            actions.custom_prompt()  -- Fallback for now
          end,
          { desc = 'AI: ' .. name, silent = true }
        )
      end
    end
  end
end

return M
