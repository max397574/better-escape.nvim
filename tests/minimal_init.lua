-- Minimal init.lua for running tests in a headless Neovim instance.
-- Usage: nvim --headless -u tests/minimal_init.lua

-- Add the plugin to the runtime path
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Disable swap files and shada for clean test runs
vim.opt.swapfile = false
vim.opt.shadafile = "NONE"
