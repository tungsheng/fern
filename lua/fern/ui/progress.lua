local M = {}

local spinner_frames = {'⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'}

local state = {
  active = false,
  frame = 1,
  timer = nil,
  start_time = nil,
  notification_id = nil
}

function M.start()
  if state.active then
    return
  end

  state.active = true
  state.start_time = vim.loop.now()
  state.frame = 1

  -- Update spinner every 100ms
  state.timer = vim.loop.new_timer()
  state.timer:start(0, 100, vim.schedule_wrap(function()
    if not state.active then
      return
    end

    state.frame = (state.frame % #spinner_frames) + 1
    local elapsed = (vim.loop.now() - state.start_time) / 1000

    local message = string.format("%s Streaming... (%.1fs)", spinner_frames[state.frame], elapsed)

    -- Update notification (if notify plugin is available)
    local has_notify, notify = pcall(require, 'notify')
    if has_notify then
      state.notification_id = notify(message, vim.log.levels.INFO, {
        title = "Fern AI",
        timeout = false,
        replace = state.notification_id,
        hide_from_history = true
      })
    else
      -- Fallback to status line message
      vim.api.nvim_echo({{message, "Normal"}}, false, {})
    end
  end))
end

function M.stop(success)
  if not state.active then
    return
  end

  state.active = false

  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end

  local elapsed = state.start_time and (vim.loop.now() - state.start_time) / 1000 or 0
  local message

  if success == false then
    message = string.format("Failed (%.1fs)", elapsed)
  else
    message = string.format("Complete (%.1fs)", elapsed)
  end

  -- Show completion notification
  local has_notify, notify = pcall(require, 'notify')
  if has_notify then
    notify(message, success == false and vim.log.levels.ERROR or vim.log.levels.INFO, {
      title = "Fern AI",
      timeout = 2000,
      replace = state.notification_id
    })
    state.notification_id = nil
  else
    vim.notify(message, success == false and vim.log.levels.ERROR or vim.log.levels.INFO)
  end

  state.start_time = nil
end

function M.update_status(message)
  if not state.active then
    return
  end

  local elapsed = state.start_time and (vim.loop.now() - state.start_time) / 1000 or 0
  local full_message = string.format("%s %s (%.1fs)", spinner_frames[state.frame], message, elapsed)

  local has_notify, notify = pcall(require, 'notify')
  if has_notify then
    state.notification_id = notify(full_message, vim.log.levels.INFO, {
      title = "Fern AI",
      timeout = false,
      replace = state.notification_id,
      hide_from_history = true
    })
  else
    vim.api.nvim_echo({{full_message, "Normal"}}, false, {})
  end
end

function M.is_active()
  return state.active
end

return M
