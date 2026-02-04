local M = {}

local config = require("nvim-cursor.config")
local stream = require("nvim-cursor.api.stream")
local errors = require("nvim-cursor.api.errors")
local logger = require("nvim-cursor.logger")

-- Current request state
local current_handle = nil
local current_stdout = nil
local current_stderr = nil

function M.cancel_current()
  if current_handle then
    logger.info("Cancelling current request")
    
    if current_stdout then
      current_stdout:close()
    end
    if current_stderr then
      current_stderr:close()
    end
    if current_handle then
      current_handle:close()
    end
    
    current_handle = nil
    current_stdout = nil
    current_stderr = nil
    
    vim.notify("Request cancelled", vim.log.levels.INFO)
  end
end

function M.send_request(prompt, context, options, on_chunk, on_complete, on_error, retry_count)
  retry_count = retry_count or 0
  
  -- Cancel previous request if exists
  if current_handle then
    M.cancel_current()
  end
  
  local opts = config.get().api.cursor
  
  if not opts.api_key then
    local err = errors.new('AUTH', 'No API key configured')
    if on_error then
      on_error(err)
    end
    return
  end
  
  logger.debug("Sending request", {
    model = opts.model,
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
    model = opts.model,
    messages = messages,
    stream = true,
    temperature = options.temperature or 0.3,
  }
  
  local json_body = vim.json.encode(request_body)
  
  -- Create temporary file for request body
  local temp_file = vim.fn.tempname()
  local f = io.open(temp_file, "w")
  if not f then
    if on_error then
      on_error("Failed to create temporary file")
    end
    return
  end
  f:write(json_body)
  f:close()
  
  -- Build curl command
  local curl_cmd = {
    "curl",
    "-N",
    "-X", "POST",
    opts.endpoint,
    "-H", "Content-Type: application/json",
    "-H", "Authorization: Bearer " .. opts.api_key,
    "--data-binary", "@" .. temp_file,
    "--no-buffer",
    "--max-time", tostring(math.floor(opts.timeout / 1000)),
  }
  
  if config.get().debug then
    vim.notify("nvim-cursor: Request - " .. vim.inspect(request_body), vim.log.levels.DEBUG)
  end
  
  -- Create stream handler
  local handler = stream.create_stream_handler(
    on_chunk,
    function()
      vim.fn.delete(temp_file)
      if on_complete then
        on_complete()
      end
    end,
    function(err)
      vim.fn.delete(temp_file)
      if on_error then
        on_error(err)
      end
    end
  )
  
  -- Execute curl with streaming
  current_stdout = vim.loop.new_pipe(false)
  current_stderr = vim.loop.new_pipe(false)
  
  current_handle = vim.loop.spawn(curl_cmd[1], {
    args = vim.list_slice(curl_cmd, 2),
    stdio = { nil, current_stdout, current_stderr }
  }, function(code, signal)
    local stdout_ref = current_stdout
    local stderr_ref = current_stderr
    local handle_ref = current_handle
    
    if stdout_ref then stdout_ref:close() end
    if stderr_ref then stderr_ref:close() end
    if handle_ref then handle_ref:close() end
    
    current_stdout = nil
    current_stderr = nil
    current_handle = nil
    
    if code ~= 0 then
      vim.schedule(function()
        local err = errors.new('NETWORK', 'Request failed with exit code: ' .. code)
        
        -- Check if we should retry
        if errors.should_retry(err, retry_count, opts.max_retries) then
          local delay = errors.get_retry_delay(retry_count + 1, opts.retry_delay)
          
          logger.info("Retrying request", {
            attempt = retry_count + 1,
            delay_ms = delay
          })
          
          vim.notify(
            string.format("Retrying request (attempt %d/%d)...", retry_count + 1, opts.max_retries),
            vim.log.levels.INFO
          )
          
          vim.defer_fn(function()
            M.send_request(prompt, context, options, on_chunk, on_complete, on_error, retry_count + 1)
          end, delay)
        else
          logger.error("Request failed after retries", { code = code, retries = retry_count })
          if on_error then
            on_error(err)
          end
        end
      end)
    else
      vim.schedule(function()
        handler.flush()
      end)
    end
  end)
  
  if not current_handle then
    local err = errors.new('NETWORK', 'Failed to start curl process')
    logger.error("Failed to start curl", {})
    if on_error then
      on_error(err)
    end
    return
  end
  
  -- Read stdout
  current_stdout:read_start(function(err, data)
    vim.schedule(function()
      handler.on_data(err, data)
    end)
  end)
  
  -- Read stderr
  local stderr_data = ""
  current_stderr:read_start(function(err, data)
    if data then
      stderr_data = stderr_data .. data
    elseif stderr_data ~= "" then
      vim.schedule(function()
        logger.debug("stderr output", { data = stderr_data })
      end)
    end
  end)
  
  -- Return cancellable handle
  return {
    cancel = function()
      M.cancel_current()
    end
  }
end

return M
