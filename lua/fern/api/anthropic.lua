local M = {}

local errors = require("fern.api.errors")
local http = require("fern.api.http")
local logger = require("fern.logger")

local PROVIDER_NAME = "anthropic"

function M.cancel_current()
  http.cancel_current(PROVIDER_NAME)
end

function M.send_request(prompt, context, options, on_chunk, on_complete, on_error, retry_count)
  retry_count = retry_count or 0

  http.cancel_current(PROVIDER_NAME)

  local config = require("fern.config")
  local opts = config.get().api.anthropic

  if not opts.api_key then
    opts.api_key = vim.env.ANTHROPIC_API_KEY
  end

  if not opts.api_key then
    local err = errors.new('AUTH', 'No API key configured for Anthropic')
    if on_error then on_error(err) end
    return
  end

  logger.debug("Sending Anthropic request", {
    model = opts.model,
    retry_count = retry_count,
    prompt_length = prompt and #prompt or 0
  })

  -- Build Anthropic-format request body
  local user_content = context
  if prompt and prompt ~= "" then
    user_content = user_content .. "\n\n" .. prompt
  end

  local request_body = {
    model = opts.model,
    max_tokens = opts.max_tokens,
    stream = true,
    messages = {
      { role = "user", content = user_content }
    },
  }

  if options.system_prompt then
    request_body.system = options.system_prompt
  end

  if options.temperature then
    request_body.temperature = options.temperature
  end

  local json_body = vim.json.encode(request_body)

  local temp_file = http.write_temp_body(json_body, on_error)
  if not temp_file then return end

  local curl_cmd = {
    "curl",
    "-sS",
    "-N",
    "-X", "POST",
    opts.endpoint,
    "-H", "Content-Type: application/json",
    "-H", "x-api-key: " .. opts.api_key,
    "-H", "anthropic-version: " .. opts.api_version,
    "--data-binary", "@" .. temp_file,
    "--no-buffer",
    "--max-time", tostring(math.floor(opts.timeout / 1000)),
  }

  if config.get().debug then
    vim.notify("fern: Anthropic Request - " .. vim.inspect(request_body), vim.log.levels.DEBUG)
  end

  -- Create Anthropic stream handler
  local anthropic_stream = require("fern.api.anthropic_stream")
  local handler = anthropic_stream.create_stream_handler(
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
    provider_name = PROVIDER_NAME,
    curl_cmd = curl_cmd,
    stream_handler = handler,
    provider_opts = opts,
    temp_file = temp_file,
    retry_count = retry_count,
    on_error = on_error,
    retry_fn = function(next_retry_count)
      M.send_request(prompt, context, options, on_chunk, on_complete, on_error, next_retry_count)
    end,
  })
end

return M
