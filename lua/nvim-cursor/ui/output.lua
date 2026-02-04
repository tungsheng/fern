local M = {}

-- State
M.buf = nil
M.win = nil
M.is_visible = false
M.config = nil

function M.setup(config)
  M.config = config
end

local function create_buffer()
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    return M.buf
  end
  
  M.buf = vim.api.nvim_create_buf(false, true)
  local config = require("nvim-cursor.config")
  local opts = config.get().ui.output
  
  vim.api.nvim_buf_set_option(M.buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(M.buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(M.buf, "swapfile", false)
  vim.api.nvim_buf_set_option(M.buf, "filetype", opts.filetype)
  vim.api.nvim_buf_set_option(M.buf, "modifiable", true)
  vim.api.nvim_buf_set_name(M.buf, "nvim-cursor://output")
  
  -- Set buffer-local keymaps
  local keymap_opts = { buffer = M.buf, noremap = true, silent = true }
  vim.keymap.set("n", "q", function() M.close() end, keymap_opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, keymap_opts)
  
  -- History navigation keymaps (if enabled)
  if opts.history.enabled then
    vim.keymap.set("n", opts.history.keymaps.next, function()
      M.show_next_history()
    end, vim.tbl_extend("force", keymap_opts, { desc = "Next response in history" }))
    
    vim.keymap.set("n", opts.history.keymaps.prev, function()
      M.show_prev_history()
    end, vim.tbl_extend("force", keymap_opts, { desc = "Previous response in history" }))
  end
  
  return M.buf
end

local function create_window()
  local buf = create_buffer()
  local opts = config.get().ui.output
  
  local position = opts.position
  local size = opts.size
  
  -- Determine split command
  local split_cmd
  if position == "right" then
    split_cmd = "botright vsplit"
  elseif position == "left" then
    split_cmd = "topleft vsplit"
  elseif position == "bottom" then
    split_cmd = "botright split"
  else
    split_cmd = "botright vsplit"
  end
  
  -- Create split
  vim.cmd(split_cmd)
  M.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(M.win, buf)
  
  -- Set window size
  if position == "right" or position == "left" then
    local width = math.floor(vim.o.columns * size / 100)
    vim.api.nvim_win_set_width(M.win, width)
  else
    local height = math.floor(vim.o.lines * size / 100)
    vim.api.nvim_win_set_height(M.win, height)
  end
  
  -- Window options
  vim.api.nvim_win_set_option(M.win, "wrap", true)
  vim.api.nvim_win_set_option(M.win, "linebreak", true)
  vim.api.nvim_win_set_option(M.win, "number", false)
  vim.api.nvim_win_set_option(M.win, "relativenumber", false)
  vim.api.nvim_win_set_option(M.win, "signcolumn", "no")
  
  M.is_visible = true
  return M.win
end

function M.open()
  if M.is_visible and M.win and vim.api.nvim_win_is_valid(M.win) then
    return M.win
  end
  
  return create_window()
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    M.win = nil
    M.is_visible = false
  end
end

function M.toggle()
  if M.is_visible and M.win and vim.api.nvim_win_is_valid(M.win) then
    M.close()
  else
    M.open()
  end
end

function M.clear()
  local buf = create_buffer()
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
end

function M.append_text(text)
  local buf = create_buffer()
  
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  
  -- Get current lines
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Split incoming text by newlines
  local new_lines = vim.split(text, "\n", { plain = true })
  
  -- If buffer is empty, just set the lines
  if #lines == 0 or (#lines == 1 and lines[1] == "") then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
  else
    -- Append to last line if it doesn't end with newline
    local last_line = lines[#lines]
    lines[#lines] = last_line .. new_lines[1]
    
    -- Add remaining lines
    for i = 2, #new_lines do
      table.insert(lines, new_lines[i])
    end
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  
  -- Auto-scroll to bottom if window is visible
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(M.win, { line_count, 0 })
  end
end

function M.set_text(text)
  M.clear()
  M.append_text(text)
end

function M.show_error(message)
  M.open()
  M.set_text("# Error\n\n" .. message)
end

function M.start_new_response()
  local buf = create_buffer()
  
  -- Add separator with timestamp
  local separator = string.format("\n\n---\n**Request at %s**\n\n", os.date("%H:%M:%S"))
  
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- If buffer has content, add separator
  if #lines > 0 and (lines[1] ~= "" or #lines > 1) then
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    table.insert(current_lines, "")
    table.insert(current_lines, "---")
    table.insert(current_lines, string.format("**Request at %s**", os.date("%H:%M:%S")))
    table.insert(current_lines, "")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, current_lines)
  end
end

function M.show_next_history()
  local history = require("nvim-cursor.history")
  local entry = history.next()
  
  if entry then
    local formatted = history.format_entry(entry)
    M.set_text(formatted)
    
    local count = history.get_count()
    local index = history.get_index()
    vim.notify(string.format("History: %d/%d", index, count), vim.log.levels.INFO)
  else
    vim.notify("Already at newest response", vim.log.levels.WARN)
  end
end

function M.show_prev_history()
  local history = require("nvim-cursor.history")
  local entry = history.prev()
  
  if entry then
    local formatted = history.format_entry(entry)
    M.set_text(formatted)
    
    local count = history.get_count()
    local index = history.get_index()
    vim.notify(string.format("History: %d/%d", index, count), vim.log.levels.INFO)
  else
    vim.notify("Already at oldest response", vim.log.levels.WARN)
  end
end

return M
