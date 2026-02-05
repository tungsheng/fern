local M = {}

local config = require("fern.config")

local providers = {
  cursor = require("fern.api.cursor"),
  openai = require("fern.api.openai"),
  anthropic = require("fern.api.anthropic"),
  openai_compat = require("fern.api.openai_compat"),
}

-- Track active provider for cancel dispatch
local active_provider_name = nil

function M.send_request(prompt, context, options, on_chunk, on_complete, on_error)
  local opts = config.get()
  local provider_name = opts.api.provider
  local provider = providers[provider_name]

  if not provider then
    if on_error then
      on_error("Unknown provider: " .. provider_name)
    end
    return
  end

  active_provider_name = provider_name
  provider.send_request(prompt, context, options, on_chunk, on_complete, on_error)
end

function M.cancel_current()
  if active_provider_name then
    local provider = providers[active_provider_name]
    if provider and provider.cancel_current then
      provider.cancel_current()
    end
  end
end

function M.register_provider(name, provider)
  providers[name] = provider
end

return M
