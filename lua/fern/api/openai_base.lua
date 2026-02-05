local M = {}

local stream = require("fern.api.stream")
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

function M.send_request(provider_name, provider_opts, prompt, context, options, on_chunk, on_complete, on_error, retry_count)
  retry_count = retry_count or 0

  -- Cancel previous request if exists
  M.cancel_current(provider_name)

  if not provider_opts.api_key then
    local err = errors.new('AUTH', 'No API key configured for ' .. provider_name)
    if on_error then on_error(err) end
    return
  end

  logger.debug("Sending request", {
    provider = provider_name,
    model = provider_opts.model,
    retry_count = retry_count,
    prompt_length = prompt and #prompt or 0
  })

  -- Build messages
  local messages = {}

  if options.system_prompt then
    table.insert(messages, {
      role = "system",
      content = options.system_prompt
    })
  end

  local user_content = context
  if prompt and prompt ~= "" then
    user_content = user_content .. "\n\n" .. prompt
  end

  table.insert(messages, {
    role = "user",
    content = user_content
  })

  -- Build request body
  local request_body = {
    model = provider_opts.model,
    messages = messages,
    stream = true,
    temperature = options.temperature or 0.3,
  }

  local json_body = vim.json.encode(request_body)

  -- Create temporary file for request body
  local temp_file = vim.fn.tempname()
  local f = io.open(temp_file, "w")
  if not f then
    if on_error then on_error("Failed to create temporary file") end
    return
  end
  f:write(json_body)
  f:close()

  -- Build curl command
  local curl_cmd = {
    "curl",
    "-N",
    "-X", "POST",
    provider_opts.endpoint,
    "-H", "Content-Type: application/json",
    "-H", "Authorization: Bearer " .. provider_opts.api_key,
    "--data-binary", "@" .. temp_file,
    "--no-buffer",
    "--max-time", tostring(math.floor(provider_opts.timeout / 1000)),
  }

  local config = require("fern.config")
  if config.get().debug then
    vim.notify("fern: Request - " .. vim.inspect(request_body), vim.log.levels.DEBUG)
  end

  -- Create stream handler
  local handler = stream.create_stream_handler(
    on_chunk,
    function()
      vim.fn.delete(temp_file)
      if on_complete then on_complete() end
    end,
    function(err)
      vim.fn.delete(temp_file)
      if on_error then on_error(err) end
    end
  )

  -- Initialize request state
  local state = {}
  active_requests[provider_name] = state

  -- Execute curl with streaming
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
            M.send_request(provider_name, provider_opts, prompt, context, options, on_chunk, on_complete, on_error, retry_count + 1)
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
    local err = errors.new('NETWORK', 'Failed to start curl process')
    logger.error("Failed to start curl", { provider = provider_name })
    if on_error then on_error(err) end
    return
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

return M
