local M = {}

local log_levels = {
  debug = 1,
  info = 2,
  warn = 3,
  error = 4
}

M.config = {
  level = "warn",
  use_console = false,
  use_file = true,
  path = vim.fn.stdpath("cache") .. "/nvim-cursor.log",
  redact_logs = true
}

function M.setup(config)
  M.config = vim.tbl_deep_extend("force", M.config, config or {})
  M.level = log_levels[M.config.level] or log_levels.warn
  
  -- Create log directory if needed
  if M.config.use_file then
    local log_dir = vim.fn.fnamemodify(M.config.path, ':h')
    vim.fn.mkdir(log_dir, 'p')
  end
end

local function redact_sensitive(data)
  if not M.config.redact_logs or type(data) ~= "table" then
    return data
  end
  
  local redacted = vim.deepcopy(data)
  
  -- Redact API keys and sensitive fields
  local sensitive_fields = { "api_key", "apiKey", "authorization", "password", "token" }
  
  local function redact_recursive(tbl)
    for key, value in pairs(tbl) do
      local key_lower = type(key) == "string" and key:lower() or ""
      
      for _, sensitive in ipairs(sensitive_fields) do
        if key_lower:match(sensitive:lower()) then
          tbl[key] = "[REDACTED]"
          break
        end
      end
      
      if type(value) == "table" then
        redact_recursive(value)
      end
    end
  end
  
  redact_recursive(redacted)
  return redacted
end

function M.log(level, message, data)
  if log_levels[level] < M.level then
    return
  end
  
  local timestamp = os.date('%Y-%m-%d %H:%M:%S')
  local data_str = ""
  
  if data then
    local safe_data = redact_sensitive(data)
    data_str = " " .. vim.inspect(safe_data)
  end
  
  local log_line = string.format('[%s] %s: %s%s', timestamp, level:upper(), message, data_str)
  
  -- Console output
  if M.config.use_console then
    print(log_line)
  end
  
  -- File output
  if M.config.use_file then
    local file = io.open(M.config.path, 'a')
    if file then
      file:write(log_line .. '\n')
      file:close()
    end
  end
end

function M.debug(message, data)
  M.log('debug', message, data)
end

function M.info(message, data)
  M.log('info', message, data)
end

function M.warn(message, data)
  M.log('warn', message, data)
end

function M.error(message, data)
  M.log('error', message, data)
end

return M
