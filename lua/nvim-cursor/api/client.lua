local M = {}

local config = require("nvim-cursor.config")

local providers = {
  cursor = require("nvim-cursor.api.cursor"),
}

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
  
  provider.send_request(prompt, context, options, on_chunk, on_complete, on_error)
end

function M.register_provider(name, provider)
  providers[name] = provider
end

return M
