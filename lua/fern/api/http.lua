local M = {}

local errors = require("fern.api.errors")
local logger = require("fern.logger")

-- Per-provider request state
local active_requests = {}

function M.cancel_current(provider_name)
  local state = active_requests[provider_name]
  if state and state.handle then
    logger.info("Cancelling current request", { provider = provider_name })

    if state.stdout then state.stdout:close() end
    if state.stderr then state.stderr:close() end
    if state.handle then state.handle:close() end

    active_requests[provider_name] = nil

    vim.notify("Request cancelled", vim.log.levels.INFO)
  end
end

--- Execute a streaming curl request with retry support.
--- @param opts table { provider_name, curl_cmd, stream_handler, provider_opts, temp_file, retry_count, retry_fn }
function M.execute(opts)
  local provider_name = opts.provider_name
  local curl_cmd = opts.curl_cmd
  local handler = opts.stream_handler
  local provider_opts = opts.provider_opts
  local temp_file = opts.temp_file
  local retry_count = opts.retry_count or 0
  local retry_fn = opts.retry_fn
  local on_error = opts.on_error

  -- Initialize request state
  local state = {}
  active_requests[provider_name] = state

  state.stdout = vim.loop.new_pipe(false)
  state.stderr = vim.loop.new_pipe(false)

  state.handle = vim.loop.spawn(curl_cmd[1], {
    args = vim.list_slice(curl_cmd, 2),
    stdio = { nil, state.stdout, state.stderr }
  }, function(code, signal)
    local s = active_requests[provider_name]
    if s then
      if s.stdout then s.stdout:close() end
      if s.stderr then s.stderr:close() end
      if s.handle then s.handle:close() end
      active_requests[provider_name] = nil
    end

    if code ~= 0 then
      vim.schedule(function()
        local err = errors.new('NETWORK', 'Request failed with exit code: ' .. code)

        if errors.should_retry(err, retry_count, provider_opts.max_retries) then
          local delay = errors.get_retry_delay(retry_count + 1, provider_opts.retry_delay)

          logger.info("Retrying request", {
            provider = provider_name,
            attempt = retry_count + 1,
            delay_ms = delay
          })

          vim.notify(
            string.format("Retrying request (attempt %d/%d)...", retry_count + 1, provider_opts.max_retries),
            vim.log.levels.INFO
          )

          vim.defer_fn(function()
            if retry_fn then retry_fn(retry_count + 1) end
          end, delay)
        else
          logger.error("Request failed after retries", { provider = provider_name, code = code, retries = retry_count })
          if on_error then on_error(err) end
        end
      end)
    else
      vim.schedule(function()
        handler.flush()
      end)
    end
  end)

  if not state.handle then
    active_requests[provider_name] = nil
    if temp_file then vim.fn.delete(temp_file) end
    local err = errors.new('NETWORK', 'Failed to start curl process')
    logger.error("Failed to start curl", { provider = provider_name })
    if on_error then on_error(err) end
    return nil
  end

  -- Read stdout
  state.stdout:read_start(function(err, data)
    vim.schedule(function()
      handler.on_data(err, data)
    end)
  end)

  -- Read stderr
  local stderr_data = ""
  state.stderr:read_start(function(err, data)
    if data then
      stderr_data = stderr_data .. data
    elseif stderr_data ~= "" then
      vim.schedule(function()
        logger.debug("stderr output", { provider = provider_name, data = stderr_data })
      end)
    end
  end)

  return {
    cancel = function()
      M.cancel_current(provider_name)
    end
  }
end

--- Write JSON body to a temp file and return the path.
--- Returns nil and calls on_error on failure.
function M.write_temp_body(json_body, on_error)
  local temp_file = vim.fn.tempname()
  local f = io.open(temp_file, "w")
  if not f then
    if on_error then on_error("Failed to create temporary file") end
    return nil
  end
  f:write(json_body)
  f:close()
  return temp_file
end

return M
