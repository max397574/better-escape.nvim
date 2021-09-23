local M = {}

local previous_chars = {}

vim.g.better_escape_flag = false
local settings = {
  mapping = { "jk", "jj" },
  timeout = 200,
}

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local function start_timeout(timeout)
  vim.g.better_escape_flag = true
  local timer = vim.loop.new_timer()
  timer:start(timeout, 0, function()
    vim.g.better_escape_flag = false
  end)
end

local function get_indices(tbl, element)
  local indices = {}
  for idx, value in ipairs(tbl) do
    if element == value then
      table.insert(indices, idx)
    end
  end
  return indices
end

local function check_timeout()
  if vim.g.better_escape_flag then
    vim.api.nvim_feedkeys(t "<BS><BS><Esc>", "n", false)
  else
    vim.g.better_escape_flag = false
  end
  previous_chars = {}
end

function M.check_charaters()
  local first_chars = {}
  local second_chars = {}
  for _, shortcut in pairs(settings.mapping) do
    table.insert(first_chars, (string.sub(shortcut, 1, 1)))
    table.insert(second_chars, (string.sub(shortcut, 2, 2)))
  end

  local timeout = settings.timeout
  table.insert(previous_chars, vim.v.char)
  local prev_char = previous_chars[#previous_chars - 1] or ""
  if
    vim.tbl_contains(second_chars, vim.v.char)
    and vim.tbl_contains(first_chars, prev_char)
  then
    local indices = get_indices(second_chars, vim.v.char)
    for _, idx in pairs(indices) do
      if first_chars[idx] == prev_char then
        check_timeout()
      end
    end
  else
    if vim.tbl_contains(first_chars, vim.v.char) then
      start_timeout(timeout)
    end
  end
end

local function validate_settings()
  if type(settings.mapping) ~= "table" then
    print "Error(better-escape.nvim): Mapping must be a table."
  end
  for _, mapping in ipairs(settings.mapping) do
    if #mapping ~= 2 then
      print "Error(better-escape.nvim): Mapping must be 2 keys."
    end
  end
  if type(settings.timeout) ~= "number" then
    print "Error(better-escape.nvim): Timeout must be a number."
  end
  if settings.timeout < 1 then
    print "Error(better-escape.nvim): Timeout must be a positive number."
  end
end

function M.setup(update)
  settings = vim.tbl_deep_extend("force", settings, update or {})
  vim.cmd [[au InsertCharPre * lua require"better_escape".check_charaters()]]
  validate_settings()
end

return M
