local M = {}

M.defaults = {
	api = {
		provider = "anthropic",
		cursor = {
			endpoint = "https://api.cursor.sh/v1/chat/completions",
			api_key = nil, -- MUST use env: CURSOR_API_KEY
			model = "gpt-4",
			timeout = 30000,
			max_retries = 3,
			retry_delay = 1000,
		},
		openai = {
			endpoint = "https://api.openai.com/v1/chat/completions",
			api_key = nil, -- MUST use env: OPENAI_API_KEY
			model = "gpt-5-mini",
			timeout = 30000,
			max_retries = 3,
			retry_delay = 1000,
		},
		anthropic = {
			endpoint = "https://api.anthropic.com/v1/messages",
			api_key = nil, -- MUST use env: ANTHROPIC_API_KEY
			model = "claude-sonnet-4-20250514",
			max_tokens = 4096,
			timeout = 30000,
			max_retries = 3,
			retry_delay = 1000,
			api_version = "2023-06-01",
		},
		openai_compat = {
			endpoint = "http://localhost:11434/v1/chat/completions",
			api_key = nil, -- Optional for local servers like Ollama
			model = "llama3",
			timeout = 60000,
			max_retries = 1,
			retry_delay = 1000,
		},
	},

	ui = {
		input = {
			width = 80,
			height = 10,
			border = "rounded",
			title = " Fern AI Prompt ",
			title_pos = "center",
		},
		output = {
			position = "right", -- right, bottom, left
			size = 50, -- percentage
			border = "rounded",
			title = " Fern AI Response ",
			filetype = "markdown",
			max_lines = 10000,
			max_line_length = 500,
			auto_scroll = true,
			preserve_on_close = true,
			show_progress = true,

			-- Response history navigation
			history = {
				enabled = true,
				max_entries = 50,
				keymaps = {
					next = "]a",
					prev = "[a",
					clear = "<leader>aC",
				},
			},
		},
	},

	keymaps = {
		enabled = true,
		mappings = {
			toggle_output = "<leader>at",
			cancel_request = "<C-c>",
			custom_prompt = "<leader>ac",
			explain_selection = "<leader>ae",
			explain_buffer = "<leader>aE",
			generate_doc = "<leader>ad",
			refactor_code = "<leader>ar",
			fix_bug = "<leader>af",
		},
	},

	-- Context extraction settings
	context = {
		include_line_numbers = true,
		include_file_path = true,
		include_filetype = true,
		surrounding_lines = 5,
		max_buffer_lines = 5000,
	},

	actions = {
		explain = {
			system_prompt = "Explain the following code in detail, including purpose, logic, and any edge cases:",
			show_diff = false,
		},
		doc = {
			system_prompt = "Generate comprehensive documentation for the following code, including function/class descriptions, parameters, return values, and usage examples:",
			show_diff = false,
		},
		refactor = {
			system_prompt = "Suggest refactoring improvements for the following code, focusing on readability, performance, and best practices:",
			show_diff = true,
		},
		fix_bug = {
			system_prompt = "Analyze this code for bugs and provide fixes with explanations:",
			show_diff = true,
		},
	},

	custom_actions = {},

	log = {
		level = "warn",
		use_console = false,
		use_file = true,
		path = vim.fn.stdpath("cache") .. "/fern.log",
		redact_logs = true,
	},

	security = {
		warn_api_key_in_config = true,
	},
}

M.options = {}

-- Map providers to their environment variable names
local env_vars = {
	cursor = "CURSOR_API_KEY",
	openai = "OPENAI_API_KEY",
	anthropic = "ANTHROPIC_API_KEY",
}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

	-- Security validation
	M.validate_security()

	return M.options
end

function M.validate_security()
	local provider = M.options.api.provider
	local provider_config = M.options.api[provider]

	if not provider_config then
		vim.notify("fern: Unknown provider '" .. provider .. "'. Run :checkhealth fern for help.", vim.log.levels.ERROR)
		return false
	end

	-- Warn if API key is hardcoded in config
	if type(provider_config.api_key) == "string" and M.options.security.warn_api_key_in_config then
		local env_var = env_vars[provider] or (provider:upper() .. "_API_KEY")
		vim.notify(
			"WARNING: API key found in config file. Use environment variable " .. env_var .. " instead.",
			vim.log.levels.WARN
		)
	end

	-- Get API key from env if not in config
	if not provider_config.api_key then
		local env_var = env_vars[provider]
		if env_var then
			provider_config.api_key = vim.env[env_var]
		end
	end

	-- Ensure API key exists (openai_compat is optional)
	if not provider_config.api_key and provider ~= "openai_compat" then
		local env_var = env_vars[provider] or (provider:upper() .. "_API_KEY")
		vim.notify(
			"fern: No API key found for provider '"
				.. provider
				.. "'. Set "
				.. env_var
				.. " environment variable.\nRun :checkhealth fern for help.",
			vim.log.levels.ERROR
		)
		return false
	end

	return true
end

function M.get()
	return M.options
end

return M
