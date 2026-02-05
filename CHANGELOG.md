# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### 🔩 Planned
- Diff view for refactoring suggestions with apply option
- Telescope integration for history browsing
- Support for additional AI providers (OpenAI, Anthropic)
- Code action integration (Neovim LSP)
- Multi-file context support
- Conversation mode (multi-turn chat)

## [0.1.1] - 2024-02-04

### 🐛 Bug Fixes

- [Core] Fix module name typo preventing plugin from loading (nnvim-cursor → nvim-cursor)

### 📝 Documentation

- Add VERSION file for version tracking
- Add version constant to main module
- Add `:CursorVersion` command to display plugin version
- Include version in health check output
- Update README with version badge

## [0.1.0] - 2024-02-04

### 📈 Features/Enhancements

#### Core Features
- [Streaming] Add real-time streaming responses from Cursor API without blocking editor
- [Context] Implement automatic context extraction with file path, line numbers, and surrounding code
- [Actions] Add predefined actions for explain, document, refactor, and fix bugs
- [Custom Prompts] Enable custom AI prompts with `<leader>ac` for any question

#### UI Components
- [Output] Create configurable split pane with markdown syntax highlighting
- [Input] Add floating input window with centered interface for custom prompts
- [Progress] Implement animated spinner with elapsed time display
- [Auto-scroll] Enable automatic scrolling to bottom during streaming
- [Toggle] Add `<leader>at` to show/hide response pane while preserving content

#### Response History
- [Navigation] Add `[a` and `]a` keymaps to navigate through previous responses
- [Storage] Store up to 50 responses by default (configurable)
- [Status] Display position in history (e.g., "3/10")
- [Clear] Add `:CursorHistoryClear` command to clear all history

#### Request Management
- [Cancellation] Enable `<C-c>` to cancel streaming requests anytime
- [Auto-cancel] Automatically cancel previous request when starting new one
- [Cleanup] Properly close handles and pipes on shutdown

#### Error Handling
- [Error Types] Implement comprehensive error detection for auth, rate limiting, timeouts, server errors
- [Auto-retry] Add automatic retry with exponential backoff (up to 3 retries by default)
- [Error Messages] Display user-friendly error messages with actionable suggestions
- [Jitter] Add jitter to retry delays to avoid thundering herd

#### Developer Experience
- [Logging] Add structured logging with configurable levels (debug, info, warn, error)
- [Redaction] Automatically redact API keys and tokens from logs
- [Health Check] Create `:checkhealth nvim-cursor` for comprehensive diagnostics
- [Documentation] Add comprehensive README, KEYMAPS, and TESTING guides
- [Security] Validate API key configuration and warn if hardcoded

#### Commands
- [Commands] Add `:CursorExplain`, `:CursorDoc`, `:CursorRefactor`, `:CursorFixBug`
- [Commands] Add `:CursorPrompt`, `:CursorToggle`, `:CursorCancel`
- [Commands] Add `:CursorHistoryClear` for history management

#### Configuration
- [Config] Provide sensible defaults that work out of the box
- [Customization] Enable full configuration override via `setup()` opts
- [Security] Enforce environment variable for API key with warnings
- [Extensions] Support custom actions without forking
- [Keymaps] Allow disabling default keymaps for custom mapping
- [UI] Add configurable output position, pane size, and border style

#### Context Extraction
- [File Info] Include file path relative to git root and programming language
- [Line Numbers] Add line numbers for code selections
- [Surrounding] Include configurable surrounding context (default 5 lines)
- [Large Files] Warn when buffer exceeds 5000 lines

### 🐛 Bug Fixes

- [Stream] Fix SSE parser to handle partial UTF-8 and JSON boundaries correctly
- [Buffer] Prevent memory issues by limiting buffer size (10k lines, 500 chars/line)
- [Cleanup] Ensure proper cleanup of resources on error or cancellation

### 🔐 Security

- [API Key] Enforce environment variable usage only, never in config files
- [Warnings] Display warning if API key detected in configuration
- [Redaction] Automatically redact sensitive data from all logs
- [Validation] Validate security setup on startup
- [Gitignore] Add `.gitignore` template to prevent accidental key commits

### 📝 Documentation

- Add comprehensive README.md with installation, usage, and configuration
- Add KEYMAPS.md with detailed keymap reference and usage examples
- Add TESTING.md with step-by-step manual testing guide
- Add SECURITY.md with security best practices and setup instructions
- Add QUICKSTART.md for 5-minute getting started guide
- Add vim help documentation at `doc/nvim-cursor.txt`
- Include architecture diagrams and component descriptions

### 🛠 Maintenance

- [Structure] Create modular architecture with clear separation of concerns
- [Dependencies] Require only Neovim 0.9+ and curl (no plugin dependencies)
- [Performance] Implement non-blocking async operations throughout
- [Testing] Add manual test suite and example files for interactive testing

### 🪛 Refactoring

- [API Client] Abstract API client to support multiple providers in future
- [Stream Handler] Implement robust SSE parser with buffering
- [State] Create single source of truth for request management
- [Error Recovery] Design graceful degradation and retry strategies

### 🔩 Tests

- Add manual test suite (`test-manual.lua`) with step-by-step validation
- Add example file (`example.lua`) for interactive testing
- Create comprehensive testing guide in TESTING.md
- Include health check system for automated validation

### 📦 Project Structure

```
nvim-cursor/
├── lua/nvim-cursor/
│   ├── init.lua           # Main entry point
│   ├── config.lua         # Configuration management
│   ├── logger.lua         # Structured logging
│   ├── history.lua        # Response history
│   ├── health.lua         # Health check system
│   ├── context.lua        # Context extraction
│   ├── actions.lua        # Action definitions
│   ├── keymaps.lua        # Keymap registration
│   ├── api/
│   │   ├── client.lua    # API client interface
│   │   ├── cursor.lua    # Cursor API implementation
│   │   ├── stream.lua    # SSE stream parser
│   │   └── errors.lua    # Error types and handling
│   └── ui/
│       ├── input.lua     # Floating input window
│       ├── output.lua    # Split pane output
│       └── progress.lua  # Progress indicators
├── doc/nvim-cursor.txt     # Vim help documentation
├── plugin/nvim-cursor.lua  # Plugin detection
├── README.md              # Main documentation
├── KEYMAPS.md            # Keymap reference
├── TESTING.md            # Testing guide
├── SECURITY.md           # Security guide
└── QUICKSTART.md         # Quick start guide
```

### 🎯 Requirements

- Neovim 0.9 or higher
- curl with HTTP/2 support
- Cursor API key

### ⚙️ Configuration

Default keymaps:
- `<leader>ae` - Explain selection
- `<leader>aE` - Explain buffer
- `<leader>ac` - Custom prompt
- `<leader>ad` - Generate documentation
- `<leader>ar` - Refactor code
- `<leader>af` - Fix bug
- `<leader>at` - Toggle output pane
- `[a` - Previous response in history
- `]a` - Next response in history
- `<C-c>` - Cancel current request

### 🙏 Acknowledgments

Built for the Neovim community with inspiration from:
- LazyVim conventions for plugin structure
- Modern AI coding assistants for UX patterns
- Neovim plugin best practices for architecture

---

## Version Numbering

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality (backwards compatible)
- **PATCH** version for bug fixes (backwards compatible)

## Contributing

When adding entries to the changelog:

1. **Use the correct category** (Features/Enhancements, Bug Fixes, Security, etc.)
2. **Add a component tag** in brackets: `[Component] Description`
3. **Keep descriptions concise** but informative
4. **Include PR links** (when applicable): `([#123](link))`
5. **Use present tense** for features: "Add", "Enable", "Create"
6. **Use past tense** for fixes: "Fixed", "Resolved", "Corrected"

Example:
```markdown
- [Streaming] Add support for cancellation with Ctrl-C ([#123](link))
- [Security] Fix API key exposure in error messages ([#124](link))
```
