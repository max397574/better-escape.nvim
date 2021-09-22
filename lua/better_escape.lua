local M = {}

local previuos_chars = {}
vim.g.better_escape_flag = false
local settings = {
	mapping = "jk",
	timeout = 200
}

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function M.check_charaters()
  local first_char = settings.mapping:sub(1, 1)
  local second_char = settings.mapping:sub(2, 2)
  local timeout = settings.timeout
  table.insert(previuos_chars, vim.v.char)
  local prev_char = previuos_chars[#previuos_chars - 1] or ""

  if vim.v.char == first_char then
    vim.g.better_escape_flag = true
    local timer = vim.loop.new_timer()
    timer:start(timeout, 0, function()
      vim.g.better_escape_flag = false
    end)
  else

    if vim.v.char == second_char and prev_char == first_char then
      if vim.g.better_escape_flag then
        vim.api.nvim_feedkeys(t "<BS><BS><Esc>", "n", false)
      else
        vim.g.better_escape_flag = false
      end
      previuos_chars = {}
    end

  end
end

local function validate_settings()
  if type(settings.mapping) ~= "string" then
    print("Error(better-escape.nvim): Mapping must be a string.")
  end
  if #settings.mapping ~= 2 then
    print("Error(better-escape.nvim): Mapping must be 2 keys.")
  end
  if type(settings.timeout) ~= "number" then
    print("Error(better-escape.nvim): Timeout must be a number.")
  end
end

function M.setup(update)
  -- settings = setmetatable(update, { __index = settings })
  settings = vim.tbl_deep_extend("force", settings, update or {})

	vim.cmd [[au InsertCharPre * lua require"better_escape".check_charaters()]]
  validate_settings()
end

return M

