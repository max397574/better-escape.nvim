local uv = require "luv"
local M = {}

local settings = {
  timeout = vim.o.timeoutlen,
  mapping = { "jk", "jj" },
  clear_empty_lines = false,
  keys_before_delete = false,
  keys = "<Esc>", -- function/string
}

local flag = false
local previous_chars = {}
local first_chars = {}
local second_chars = {}
local timer = nil

local function start_timeout()
  flag = true

  if timer then
    uv.timer_stop(timer)
    uv.close(timer)
    timer = nil
  end

  timer = vim.defer_fn(function()
    flag = false
    timer = nil
  end, settings.timeout)
end

---@param tbl table table to search through
---@param element any element to search in tbl
---@return table indices
--- Search for indices in tbl where element occurs
local function get_indices(tbl, element)
  local indices = {}
  for idx, value in ipairs(tbl) do
    if element == value then
      table.insert(indices, idx)
    end
  end
  return indices
end

---@param keys string keys to feed
--- Replace keys with termcodes and feed them
local function feed(keys)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, true, true),
    "n",
    false
  )
end
local function check_timeout()
  if flag then
    if settings.keys_before_delete then
      feed(type(settings.keys) == "string" and settings.keys or settings.keys())
    end
    feed "<BS><BS>" -- delete the characters from the mapping
    -- if keys is string use it, else use it as a function
    if not settings.keys_before_delete then
      feed(type(settings.keys) == "string" and settings.keys or settings.keys())
    end
    if settings.clear_empty_lines then
      local current_line = vim.api.nvim_get_current_line()
      if string.match(current_line, "^%s+j$") then
        feed '0"_D'
      end
    end
    previous_chars = {}
    return true
  end
  return false
end

local function parse_mapping()
  -- if mapping is a string (single mapping) make it a table
  if type(settings.mapping) == "string" then
    settings.mapping = { settings.mapping }
  end
end

function M.check_charaters()
  local char = vim.v.char

  table.insert(previous_chars, char)
  local prev_char = previous_chars[#previous_chars - 1] or ""

  local indices = get_indices(second_chars, char)
  local matched = false

  -- if char == second_chars[idx] and prev_char == first_chars[idx] as well
  -- then matched = true
  for _, idx in ipairs(indices) do
    if first_chars[idx] == prev_char then
      matched = check_timeout()
    end
  end

  -- if can't find a match, and the typed char is first in a mapping, start the timeout
  if not matched and vim.tbl_contains(first_chars, char) then
    start_timeout()
  end
end

local function validate_settings()
  assert(
    type(settings.mapping) == "table",
    "Error(better-escape.nvim): Mapping must be a table."
  )

  for _, mapping in ipairs(settings.mapping) do
    assert(#mapping == 2, "Error(better-escape.nvim): Mapping must be 2 keys.")
  end

  if settings.timeout then
    assert(
      type(settings.timeout) == "number",
      "Error(better-escape.nvim): Timeout must be a number."
    )
    assert(
      settings.timeout >= 1,
      "Error(better-escape.nvim): Timeout must be a positive number."
    )
  end

  assert(
    vim.tbl_contains({ "string", "function" }, type(settings.keys)),
    "Error(better-escape.nvim): Keys must be a function or string."
  )
end

function M.setup(update)
  if vim.g.better_escape_loaded then
    return
  end
  vim.g.better_escape_loaded = true
  settings = vim.tbl_deep_extend("force", settings, update or {})
  parse_mapping()
  local ok, msg = pcall(validate_settings)
  if ok then
    -- create tables with the first and seconds chars of the mappings
    for _, shortcut in ipairs(settings.mapping) do
      table.insert(first_chars, (string.sub(shortcut, 1, 1)))
      table.insert(second_chars, (string.sub(shortcut, 2, 2)))
    end

    vim.cmd [[au InsertCharPre * lua require"better_escape".check_charaters()]]
  else
    vim.notify(msg, vim.log.levels.ERROR)
  end
end

return M
