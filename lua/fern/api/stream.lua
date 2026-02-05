local M = {}

function M.parse_sse_chunk(chunk)
  local results = {}
  
  -- Split by double newlines to get individual events
  local events = vim.split(chunk, "\n\n", { plain = true })
  
  for _, event in ipairs(events) do
    if event:match("^data: ") then
      local data = event:gsub("^data: ", "")
      
      -- Skip [DONE] marker
      if data:match("%[DONE%]") then
        goto continue
      end
      
      -- Try to parse JSON
      local ok, parsed = pcall(vim.json.decode, data)
      if ok and parsed then
        -- Extract content from delta
        if parsed.choices and parsed.choices[1] then
          local delta = parsed.choices[1].delta
          if delta and delta.content then
            table.insert(results, delta.content)
          end
        end
      end
    end
    ::continue::
  end
  
  return results
end

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
      if ok and parsed and parsed.error then
        local msg = parsed.error.message or vim.inspect(parsed.error)
        if on_error then on_error(msg) end
        return
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
        if on_error then
          on_error(err)
        end
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

      -- Append to buffer
      buffer = buffer .. data

      -- Process complete lines
      local lines = vim.split(buffer, "\n", { plain = true })

      -- Keep incomplete line in buffer
      buffer = lines[#lines]

      -- Process complete lines
      for i = 1, #lines - 1 do
        local line = lines[i]
        if line:match("^data: ") then
          local data_content = line:gsub("^data: ", "")

          if data_content:match("%[DONE%]") then
            finish()
            return
          end

          local ok, parsed = pcall(vim.json.decode, data_content)
          if ok and parsed then
            if parsed.choices and parsed.choices[1] then
              local delta = parsed.choices[1].delta
              if delta and delta.content then
                has_content = true
                if on_chunk then
                  on_chunk(delta.content)
                end
              end
            end

            if parsed.error then
              if on_error then
                on_error(parsed.error.message or vim.inspect(parsed.error))
              end
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
