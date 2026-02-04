local M = {}

function M.get_visual_selection()
  -- Save original position
  local saved_reg = vim.fn.getreg('"')
  local saved_regtype = vim.fn.getregtype('"')
  
  -- Yank visual selection to unnamed register
  vim.cmd('noautocmd normal! "vy')
  local selection = vim.fn.getreg('"')
  
  -- Restore register
  vim.fn.setreg('"', saved_reg, saved_regtype)
  
  return selection
end

function M.get_current_buffer()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return table.concat(lines, "\n")
end

function M.get_buffer_info()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  
  -- Get relative path if in a git repo
  local relative_path = filepath
  if filepath ~= "" then
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
    if git_root and git_root ~= "" then
      relative_path = filepath:gsub("^" .. vim.pesc(git_root) .. "/", "")
    else
      relative_path = vim.fn.fnamemodify(filepath, ":t")
    end
  end
  
  return {
    filepath = relative_path,
    filetype = filetype,
    full_path = filepath,
  }
end

function M.build_context(text, mode)
  local info = M.get_buffer_info()
  local context_parts = {}
  
  -- Add file information
  if info.filepath and info.filepath ~= "" then
    table.insert(context_parts, "File: " .. info.filepath)
  end
  
  if info.filetype and info.filetype ~= "" then
    table.insert(context_parts, "Language: " .. info.filetype)
  end
  
  -- Add mode information
  if mode == "selection" then
    table.insert(context_parts, "Context: Selected code")
  elseif mode == "buffer" then
    table.insert(context_parts, "Context: Full buffer")
  end
  
  table.insert(context_parts, "")
  table.insert(context_parts, "Code:")
  table.insert(context_parts, "```" .. (info.filetype or ""))
  table.insert(context_parts, text)
  table.insert(context_parts, "```")
  
  return table.concat(context_parts, "\n")
end

function M.get_context(mode)
  local text
  local context_mode
  
  if mode == "visual" or mode == "selection" then
    text = M.get_visual_selection()
    context_mode = "selection"
    
    if not text or text == "" then
      vim.notify("nvim-cursor: No text selected", vim.log.levels.WARN)
      return nil
    end
  else
    text = M.get_current_buffer()
    context_mode = "buffer"
    
    if not text or text == "" then
      vim.notify("nvim-cursor: Buffer is empty", vim.log.levels.WARN)
      return nil
    end
  end
  
  return M.build_context(text, context_mode)
end

return M
