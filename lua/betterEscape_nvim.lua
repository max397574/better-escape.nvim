local api = vim.api
local M = {}
local settings = {}

settings.mapping = "jk"
settings.timeout = "150"

function M.setup(update)
  settings = setmetatable(update, { __index = settings })
end

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local previuosly_typed_chars = {}

function M.check_charaters()
  local first_char = string.sub(settings.mapping,1,1)
  local second_char = string.sub(settings.mapping,2,2)
  table.insert(previuosly_typed_chars, vim.v.char)
  local prev_char = previuosly_typed_chars[#previuosly_typed_chars-1] or ""

  if vim.v.char == second_char and prev_char == first_char then
    vim.fn.feedkeys(t('<Esc>').."xhx", 'i')
    previuosly_typed_chars = {}
  end
  vim.loop.new_timer(settings.timeout)
  previuosly_typed_chars = {}
end

local function create_mappings()
  vim.cmd [[au InsertCharPre * lua require"betterEscape_nvim".check_charaters()]]
end

function M.init()
  create_mappings()
end


return M
