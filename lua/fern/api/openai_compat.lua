local M = {}

local openai_base = require("fern.api.openai_base")
local config = require("fern.config")

function M.cancel_current()
  openai_base.cancel_current("openai_compat")
end

function M.send_request(prompt, context, options, on_chunk, on_complete, on_error, retry_count)
  local opts = vim.deepcopy(config.get().api.openai_compat)

  -- API key is optional for local servers like Ollama
  if not opts.api_key then
    local env_key = vim.env.OPENAI_COMPAT_API_KEY
    if env_key and env_key ~= "" then
      opts.api_key = env_key
    else
      -- Use a dummy key so openai_base won't reject the request
      opts.api_key = "not-required"
    end
  end

  openai_base.send_request("openai_compat", opts, prompt, context, options, on_chunk, on_complete, on_error, retry_count)
end

return M
