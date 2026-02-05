local M = {}

function M.create_stream_handler(on_chunk, on_complete, on_error)
  local buffer = ""

  return {
    on_data = function(err, data)
      if err then
        if on_error then on_error(err) end
        return
      end

      if not data then
        if on_complete then on_complete() end
        return
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
                if on_chunk then
                  on_chunk(parsed.delta.text)
                end
              end
            end

            -- Handle message_stop event
            if parsed.type == "message_stop" then
              if on_complete then
                on_complete()
              end
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
      if buffer ~= "" then
        if on_complete then on_complete() end
      end
    end
  }
end

return M
