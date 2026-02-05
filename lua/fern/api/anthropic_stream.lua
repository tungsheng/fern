local M = {}

function M.create_stream_handler(on_chunk, on_complete, on_error)
  local buffer = ""
  local completed = false
  local has_content = false
  local raw_data = ""

  local function finish()
    if completed then return end
    completed = true

    -- If no content was delivered, the response may be a non-SSE error
    if not has_content and raw_data ~= "" then
      local trimmed = vim.trim(raw_data)
      local ok, parsed = pcall(vim.json.decode, trimmed)
      if ok and parsed then
        -- Anthropic error format: {"type": "error", "error": {"type": "...", "message": "..."}}
        if parsed.type == "error" and parsed.error then
          local msg = parsed.error.message or vim.inspect(parsed.error)
          if on_error then on_error(msg) end
          return
        end
        -- Generic error field
        if parsed.error then
          local msg = parsed.error.message or vim.inspect(parsed.error)
          if on_error then on_error(msg) end
          return
        end
      end
      -- Non-JSON or unknown error response
      if trimmed ~= "" then
        if on_error then
          on_error("Unexpected response from API:\n" .. string.sub(trimmed, 1, 500))
        end
        return
      end
    end

    if on_complete then on_complete() end
  end

  return {
    on_data = function(err, data)
      if err then
        if on_error then on_error(err) end
        return
      end

      if not data then
        finish()
        return
      end

      -- Track raw data for error detection (only while no content received)
      if not has_content then
        raw_data = raw_data .. data
      end

      buffer = buffer .. data

      local lines = vim.split(buffer, "\n", { plain = true })
      buffer = lines[#lines]

      for i = 1, #lines - 1 do
        local line = lines[i]

        if line:match("^data: ") then
          local data_content = line:gsub("^data: ", "")

          local ok, parsed = pcall(vim.json.decode, data_content)
          if ok and parsed then
            -- Handle content_block_delta events
            if parsed.type == "content_block_delta" and parsed.delta then
              if parsed.delta.text then
                has_content = true
                if on_chunk then
                  on_chunk(parsed.delta.text)
                end
              end
            end

            -- Handle message_stop event
            if parsed.type == "message_stop" then
              finish()
              return
            end

            -- Handle errors in stream
            if parsed.type == "error" then
              if on_error then
                local msg = parsed.error and parsed.error.message or vim.inspect(parsed)
                on_error(msg)
              end
              return
            end
          end
        end
      end
    end,

    flush = function()
      finish()
    end
  }
end

return M
