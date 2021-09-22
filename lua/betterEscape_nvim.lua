local api = vim.api
local M = {}
local settings = {}

settings.mapping = "jk"
settings.timeout = "300"

function M.setup(update)
  settings = setmetatable(update, { __index = settings })
end

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local previuosly_typed_chars = {}

BetterEscape_nvim_time = false

function M.check_charaters()
  local first_char = string.sub(settings.mapping,1,1)
  local second_char = string.sub(settings.mapping,2,2)
  local timeout = tonumber(settings.timeout)
  table.insert(previuosly_typed_chars, vim.v.char)
  local prev_char = previuosly_typed_chars[#previuosly_typed_chars-1] or ""
  if vim.v.char == first_char then
    BetterEscape_nvim_time = true
    local timer = vim.loop.new_timer()
    timer:start(timeout, 0, function()
      BetterEscape_nvim_time = false
    end)
  else
    if vim.v.char == second_char and prev_char == first_char then
      if BetterEscape_nvim_time then
        vim.fn.feedkeys(t('<BS>')..t('<BS>')..t('<Esc>'), 'i')
      else
        BetterEscape_nvim_time = false
      end
      previuosly_typed_chars = {}
    end
  end

end

local function create_autocmds()
  vim.cmd [[au InsertCharPre * lua require"betterEscape_nvim".check_charaters()]]
end

function M.init()
  create_autocmds()
end


return M
