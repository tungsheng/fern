local M = {}

local history = {}
local current_index = 0
local max_entries = 50

function M.setup(config)
  if config and config.max_entries then
    max_entries = config.max_entries
  end
end

function M.add_entry(request, response)
  local entry = {
    timestamp = os.time(),
    request = request,
    response = response,
    formatted_time = os.date("%Y-%m-%d %H:%M:%S")
  }
  
  table.insert(history, entry)
  
  -- Limit history size
  while #history > max_entries do
    table.remove(history, 1)
  end
  
  current_index = #history
  return current_index
end

function M.next()
  if current_index < #history then
    current_index = current_index + 1
    return history[current_index]
  end
  return nil
end

function M.prev()
  if current_index > 1 then
    current_index = current_index - 1
    return history[current_index]
  end
  return nil
end

function M.current()
  if current_index > 0 and current_index <= #history then
    return history[current_index]
  end
  return nil
end

function M.clear()
  history = {}
  current_index = 0
end

function M.get_all()
  return history
end

function M.get_count()
  return #history
end

function M.get_index()
  return current_index
end

function M.set_index(index)
  if index >= 1 and index <= #history then
    current_index = index
    return history[current_index]
  end
  return nil
end

function M.format_entry(entry)
  if not entry then
    return nil
  end
  
  local parts = {
    string.format("---\n**Request at %s**\n", entry.formatted_time),
    "",
    entry.response
  }
  
  return table.concat(parts, "\n")
end

return M
