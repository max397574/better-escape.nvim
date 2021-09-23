local M = {}

local settings = {
  mapping = { "jk", "jj" },
  keys = "<Esc>", -- function/string
}

local flag = false
local previous_chars = {}
local first_chars = {}
local second_chars = {}

local function start_timeout()
  flag = true
  vim.defer_fn(function()
    flag = false
  end, settings.timeout or vim.o.timeoutlen)
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

local function feed(keys)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, true, true),
    "n",
    false
  )
end

local function check_timeout()
  if flag then
    feed "<BS><BS>"
    feed(type(settings.keys) == "string" and settings.keys or settings.keys())
  end
  previous_chars = {}
end

local function parse_mapping()
  if type(settings.mapping) == "string" then
    settings.mapping = {settings.mapping}
  end
end

function M.check_charaters()
  local char = vim.v.char


  table.insert(previous_chars, char)
  local prev_char = previous_chars[#previous_chars - 1] or ""

  if
    vim.tbl_contains(second_chars, char)
    and vim.tbl_contains(first_chars, prev_char)
  then
    local indices = get_indices(second_chars, char)
    for _, idx in ipairs(indices) do
      if first_chars[idx] == prev_char then
        check_timeout()
      end
    end
  else
    if vim.tbl_contains(first_chars, char) then
      start_timeout()
    end
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
  settings = vim.tbl_deep_extend("force", settings, update or {})
  parse_mapping()
  local ok, msg = pcall(validate_settings)
  if ok then
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
