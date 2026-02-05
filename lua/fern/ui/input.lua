local M = {}

local config = require("fern.config")

function M.get_input(callback)
  local opts = config.get().ui.input

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  -- Calculate window position (centered)
  local width = opts.width
  local height = opts.height
  local ui = vim.api.nvim_list_uis()[1]
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = (ui.width - width) / 2,
    row = (ui.height - height) / 2,
    style = "minimal",
    border = opts.border,
    title = opts.title,
    title_pos = "center",
  }

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.api.nvim_win_set_option(win, "wrap", true)

  -- Add placeholder text
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "# Enter your prompt here", "", "" })
  vim.api.nvim_win_set_cursor(win, { 3, 0 })

  -- Start in insert mode
  vim.cmd("startinsert")

  -- Submit handler
  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    vim.api.nvim_win_close(win, true)

    -- Filter out the placeholder line and empty lines
    local prompt_lines = {}
    for i, line in ipairs(lines) do
      if i > 1 and line ~= "" then
        table.insert(prompt_lines, line)
      end
    end

    local prompt = table.concat(prompt_lines, "\n"):gsub("^%s*(.-)%s*$", "%1")

    if prompt ~= "" then
      callback(prompt)
    else
      vim.notify("fern: Empty prompt, cancelled", vim.log.levels.INFO)
    end
  end

  -- Cancel handler
  local function cancel()
    vim.api.nvim_win_close(win, true)
    vim.notify("fern: Prompt cancelled", vim.log.levels.INFO)
  end

  -- Set keymaps
  local keymap_opts = { buffer = buf, noremap = true, silent = true }
  vim.keymap.set("n", "<CR>", submit, keymap_opts)
  vim.keymap.set("n", "<Esc>", cancel, keymap_opts)
  vim.keymap.set("n", "q", cancel, keymap_opts)

  -- Submit on Ctrl-Enter in insert mode
  vim.keymap.set("i", "<C-CR>", function()
    vim.cmd("stopinsert")
    submit()
  end, keymap_opts)
end

return M
