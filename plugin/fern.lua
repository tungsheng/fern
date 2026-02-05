-- fern: AI-powered code assistance for Neovim
-- Automatically loaded by Neovim's plugin system

if vim.g.loaded_fern then
  return
end
vim.g.loaded_fern = 1

-- Don't initialize if not running Neovim
if vim.fn.has("nvim-0.9.0") ~= 1 then
  vim.notify("fern requires Neovim >= 0.9.0", vim.log.levels.ERROR)
  return
end

-- Plugin will be initialized when user calls setup() or lazy.nvim does it
-- No automatic initialization to allow user configuration
