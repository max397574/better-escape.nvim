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
    table.insert(previuosly_typed_chars, vim.v.char)
    local prev_char = previuosly_typed_chars[#previuosly_typed_chars-1] or ""

    if vim.v.char == "k" and prev_char == "j" then
        vim.fn.feedkeys(t('<Esc>').."xhx", 'i')
    end
end

local function create_mappings()
  vim.cmd [[au InsertCharPre * lua require"betterEscape_nvim".check_charaters()]]
end

function M.init()
  create_mappings()
end


return M
