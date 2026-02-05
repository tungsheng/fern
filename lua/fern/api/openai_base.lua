local M = {}

local stream = require("fern.api.stream")
local errors = require("fern.api.errors")
local http = require("fern.api.http")
local logger = require("fern.logger")

function M.cancel_current(provider_name)
  http.cancel_current(provider_name)
end

function M.send_request(provider_name, provider_opts, prompt, context, options, on_chunk, on_complete, on_error, retry_count)
  retry_count = retry_count or 0

  -- Cancel previous request if exists
  http.cancel_current(provider_name)

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

  local temp_file = http.write_temp_body(json_body, on_error)
  if not temp_file then return end

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

  return http.execute({
    provider_name = provider_name,
    curl_cmd = curl_cmd,
    stream_handler = handler,
    provider_opts = provider_opts,
    temp_file = temp_file,
    retry_count = retry_count,
    on_error = on_error,
    retry_fn = function(next_retry_count)
      M.send_request(provider_name, provider_opts, prompt, context, options, on_chunk, on_complete, on_error, next_retry_count)
    end,
  })
end

return M
