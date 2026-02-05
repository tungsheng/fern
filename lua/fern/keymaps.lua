local M = {}

function M.setup(config)
  if not config.keymaps.enabled then
    return
  end

  local mappings = config.keymaps.mappings
  local actions = require("fern.actions")
  local output = require("fern.ui.output")
  local client = require("fern.api.client")

  -- Toggle output pane (works in any mode)
  if mappings.toggle_output then
    vim.keymap.set({ "n", "v" }, mappings.toggle_output, function()
      output.toggle()
    end, { desc = "AI: Toggle output pane", silent = true })
  end

  -- Cancel current request
  if mappings.cancel_request then
    vim.keymap.set({ "n", "v" }, mappings.cancel_request, function()
      client.cancel_current()
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
        local ac = action_config
        vim.keymap.set(
          ac.mode or 'v',
          ac.keymap,
          function()
            actions.execute_custom_action(ac)
          end,
          { desc = 'AI: ' .. name, silent = true }
        )
      end
    end
  end
end

return M
