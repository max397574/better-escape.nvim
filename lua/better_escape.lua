local M = {}

local api = vim.api

local settings = {
  mapping = { "jk", "jj" },
  timeout = 200,
}

local flag = false
local previous_chars = {}
local first_chars = {}
local second_chars = {}

local function start_timeout()
  flag = true
  vim.defer_fn(function()
    flag = false
  end, settings.timeout)
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

local check_timeout = (function()
  local keys = api.nvim_replace_termcodes("<BS><BS><Esc>", true, true, true)
  return function()
    if flag then
      api.nvim_feedkeys(keys, "n", false)
    end
    previous_chars = {}
  end
end)()

function M.check_charaters()
  table.insert(previous_chars, vim.v.char)
  local prev_char = previous_chars[#previous_chars - 1] or ""
  if
    vim.tbl_contains(second_chars, vim.v.char)
    and vim.tbl_contains(first_chars, prev_char)
  then
    local indices = get_indices(second_chars, vim.v.char)
    for _, idx in ipairs(indices) do
      if first_chars[idx] == prev_char then
        check_timeout()
      end
    end
  else
    if vim.tbl_contains(first_chars, vim.v.char) then
      start_timeout()
    end
  end
end

local function error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

local function validate_settings()
  if type(settings.mapping) ~= "table" then
    error "Error(better-escape.nvim): Mapping must be a table."
    return
  end
  for _, mapping in ipairs(settings.mapping) do
    if #mapping ~= 2 then
      error "Error(better-escape.nvim): Mapping must be 2 keys."
      return
    end
  end
  if type(settings.timeout) ~= "number" then
    error "Error(better-escape.nvim): Timeout must be a number."
    return
  end
  if settings.timeout < 1 then
    error "Error(better-escape.nvim): Timeout must be a positive number."
    return
  end
  return true
end

function M.setup(update)
  settings = vim.tbl_deep_extend("force", settings, update or {})
  if validate_settings() then
    for _, shortcut in pairs(settings.mapping) do
      table.insert(first_chars, (string.sub(shortcut, 1, 1)))
      table.insert(second_chars, (string.sub(shortcut, 2, 2)))
    end
    vim.cmd [[au InsertCharPre * lua require"better_escape".check_charaters()]]
  end
end

return M
