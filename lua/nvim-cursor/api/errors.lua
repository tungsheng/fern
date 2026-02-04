local M = {}

M.ErrorTypes = {
  AUTH = {
    code = 401,
    message = "Invalid API key",
    suggestion = "Set CURSOR_API_KEY environment variable: export CURSOR_API_KEY=your_key_here",
    retry = false
  },
  RATE_LIMIT = {
    code = 429,
    message = "Rate limit exceeded",
    suggestion = "Wait a moment and try again. The plugin will automatically retry.",
    retry = true
  },
  TIMEOUT = {
    code = 408,
    message = "Request timeout",
    suggestion = "Check your internet connection or try increasing the timeout in config.",
    retry = true
  },
  SERVER = {
    code = 500,
    message = "Server error",
    suggestion = "Cursor API may be experiencing issues. Try again later.",
    retry = true
  },
  NETWORK = {
    code = 0,
    message = "Network error",
    suggestion = "Check your internet connection and verify the API endpoint is accessible.",
    retry = true
  },
  PARSE = {
    code = 0,
    message = "Failed to parse response",
    suggestion = "This may be a temporary issue with the API response format. Try again.",
    retry = false
  },
  INVALID_CONFIG = {
    code = 0,
    message = "Invalid configuration",
    suggestion = "Check your nvim-cursor configuration. Run :checkhealth nvim-cursor for diagnostics.",
    retry = false
  }
}

function M.new(type_name, details)
  local err_type = M.ErrorTypes[type_name] or M.ErrorTypes.NETWORK
  return {
    type = type_name,
    code = err_type.code,
    message = err_type.message,
    suggestion = err_type.suggestion,
    details = details,
    retry = err_type.retry
  }
end

function M.from_http_error(err)
  -- Check if it's a table with status code
  if type(err) == "table" and err.status then
    if err.status == 401 or err.status == 403 then
      return M.new('AUTH', err.message or err.body)
    elseif err.status == 429 then
      return M.new('RATE_LIMIT', err.message or err.body)
    elseif err.status == 408 or err.status == 504 then
      return M.new('TIMEOUT', err.message or err.body)
    elseif err.status >= 500 then
      return M.new('SERVER', err.message or err.body)
    end
  end
  
  -- Check for common error messages
  local err_str = tostring(err)
  
  if err_str:match("timeout") or err_str:match("timed out") then
    return M.new('TIMEOUT', err_str)
  elseif err_str:match("connection") or err_str:match("network") then
    return M.new('NETWORK', err_str)
  elseif err_str:match("parse") or err_str:match("json") then
    return M.new('PARSE', err_str)
  elseif err_str:match("unauthorized") or err_str:match("forbidden") then
    return M.new('AUTH', err_str)
  end
  
  return M.new('NETWORK', err_str)
end

function M.format_for_user(err)
  local parts = {
    "❌ **Error: " .. err.message .. "**",
    ""
  }
  
  if err.details then
    table.insert(parts, "Details: " .. tostring(err.details))
    table.insert(parts, "")
  end
  
  if err.suggestion then
    table.insert(parts, "💡 **Suggestion:**")
    table.insert(parts, err.suggestion)
  end
  
  table.insert(parts, "")
  table.insert(parts, "For more help, run: `:checkhealth nvim-cursor`")
  
  return table.concat(parts, "\n")
end

function M.should_retry(err, attempt, max_retries)
  if not err.retry then
    return false
  end
  
  if attempt >= max_retries then
    return false
  end
  
  return true
end

function M.get_retry_delay(attempt, base_delay)
  -- Exponential backoff: base_delay * 2^attempt
  -- With jitter to avoid thundering herd
  local delay = base_delay * math.pow(2, attempt - 1)
  local jitter = math.random(0, 100)
  return delay + jitter
end

return M
