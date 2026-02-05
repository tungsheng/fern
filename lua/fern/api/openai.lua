local M = {}

local openai_base = require("fern.api.openai_base")
local config = require("fern.config")

function M.cancel_current()
  openai_base.cancel_current("openai")
end

function M.send_request(prompt, context, options, on_chunk, on_complete, on_error, retry_count)
  local opts = config.get().api.openai

  if not opts.api_key then
    opts.api_key = vim.env.OPENAI_API_KEY
  end

  openai_base.send_request("openai", opts, prompt, context, options, on_chunk, on_complete, on_error, retry_count)
end

return M
