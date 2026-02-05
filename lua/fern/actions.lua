local M = {}

local config = require("fern.config")
local context = require("fern.context")
local client = require("fern.api.client")
local output = require("fern.ui.output")
local input = require("fern.ui.input")
local progress = require("fern.ui.progress")
local history = require("fern.history")
local logger = require("fern.logger")

local current_response = {}

local function execute_action(action_config, mode, custom_prompt)
	-- Get context
	local ctx = context.get_context(mode)
	if not ctx then
		return
	end

	logger.info("Executing action", {
		mode = mode,
		has_custom_prompt = custom_prompt ~= nil and custom_prompt ~= "",
	})

	-- Open output pane
	output.open()
	output.start_new_response()

	-- Start progress indicator
	if config.get().ui.output.show_progress then
		progress.start()
	end

	-- Reset current response buffer
	current_response = {}

	-- Prepare options
	local options = {
		system_prompt = action_config.system_prompt,
		temperature = action_config.temperature,
	}

	-- Send request with streaming (pcall-protected to catch any Lua errors)
	local ok, request_err = pcall(function()
		client.send_request(custom_prompt, ctx, options, function(chunk)
			-- On chunk received
			vim.schedule(function()
				table.insert(current_response, chunk)
				output.append_text(chunk)
			end)
		end, function()
			-- On complete
			vim.schedule(function()
				progress.stop(true)

				-- Save to history
				local response_text = table.concat(current_response, "")
				history.add_entry({
					prompt = custom_prompt or action_config.system_prompt,
					context = ctx,
					mode = mode,
				}, response_text)

				logger.info("Action completed successfully", {
					response_length = #response_text,
				})

				current_response = {}
			end)
		end, function(err)
			-- On error
			vim.schedule(function()
				progress.stop(false)

				local errors = require("fern.api.errors")
				local error_obj = type(err) == "table" and err or errors.from_http_error(err)
				local formatted = errors.format_for_user(error_obj)

				output.append_text("\n\n" .. formatted)

				logger.error("Action failed", {
					error_type = error_obj.type,
					error_message = error_obj.message,
				})

				current_response = {}
			end)
		end)
	end)

	if not ok then
		progress.stop(false)
		output.show_error(tostring(request_err))
		logger.error("Request failed to send", { error = tostring(request_err) })
		current_response = {}
	end
end

function M.explain_selection()
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		local action_config = config.get().actions.explain
		execute_action(action_config, "selection", nil)
	else
		vim.notify("fern: Please select code in visual mode", vim.log.levels.WARN)
	end
end

function M.explain_buffer()
	local action_config = config.get().actions.explain
	execute_action(action_config, "buffer", nil)
end

function M.generate_doc()
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		local action_config = config.get().actions.doc
		execute_action(action_config, "selection", nil)
	else
		vim.notify("fern: Please select code in visual mode", vim.log.levels.WARN)
	end
end

function M.refactor_code()
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		local action_config = config.get().actions.refactor
		execute_action(action_config, "selection", nil)
	else
		vim.notify("fern: Please select code in visual mode", vim.log.levels.WARN)
	end
end

function M.fix_bug()
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		local action_config = config.get().actions.fix_bug
		execute_action(action_config, "selection", nil)
	else
		vim.notify("fern: Please select code in visual mode", vim.log.levels.WARN)
	end
end

function M.custom_prompt()
	input.get_input(function(prompt)
		if not prompt or prompt == "" then
			return
		end

		-- Determine context mode based on current mode
		local mode = vim.fn.mode()
		local context_mode

		if mode == "v" or mode == "V" or mode == "\22" then
			context_mode = "selection"
		else
			context_mode = "buffer"
		end

		-- Use a generic action config for custom prompts
		local action_config = {
			system_prompt = "You are a helpful AI assistant. Respond to the user's request about the provided code.",
			temperature = 1,
		}

		execute_action(action_config, context_mode, prompt)
	end)
end

function M.execute_custom_action(action_config)
	local mode = vim.fn.mode()
	local context_mode

	if mode == "v" or mode == "V" or mode == "\22" then
		context_mode = "selection"
	else
		context_mode = "buffer"
	end

	execute_action(action_config, context_mode, nil)
end

return M
