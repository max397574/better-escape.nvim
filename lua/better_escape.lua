local M = {}

local api = vim.api

local settings = {
    timeout = vim.o.timeoutlen,
    mapping = { "jk", "jj" },
    clear_empty_lines = false,
    ---@type string|function
    keys = "<Esc>",
}

local first_chars = {}
local second_chars = {}

---@class State
---@field char string
---@field modified boolean

local timer
local waiting = false
---@type State[]
local input_states = {}

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
    api.nvim_feedkeys(
        api.nvim_replace_termcodes(keys, true, true, true),
        "n",
        false
    )
end

local function start_timer()
    waiting = true

    if timer then
        timer:stop()
    end

    timer = vim.defer_fn(function()
        waiting = false
    end, settings.timeout)
end

local function get_keys()
    -- if keys is string use it, else use it as a function
    return type(settings.keys) == "string" and settings.keys or settings.keys()
end

local function check_timeout()
    if waiting then
        feed("<BS><BS>") -- delete the characters from the mapping
        feed(get_keys())
        if settings.clear_empty_lines then
            local current_line = api.nvim_get_current_line()
            if string.match(current_line, "^%s+j$") then
                vim.schedule(function()
                    feed('0"_D')
                end)
            end
        end

        waiting = false -- more timely
        return true
    end
    return false
end

function M.check_charaters()
    local char = vim.v.char
    table.insert(input_states, { char = char, modified = vim.bo.modified })

    local matched = false
    if #input_states >= 2 then
        ---@type State
        local prev_state = input_states[#input_states - 1]
        local indices = get_indices(second_chars, char)
        -- if char == second_chars[idx] and prev_char == first_chars[idx] as well
        -- then matched = true
        for _, idx in ipairs(indices) do
            if first_chars[idx] == prev_state.char then
                matched = check_timeout()
                break
            end
        end

        if matched then
            input_states = {}
            vim.schedule(function()
                vim.bo.modified = prev_state.modified
            end)
        end
    end

    -- if can't find a match, and the typed char is first in a mapping, start the timeout
    if not matched and vim.tbl_contains(first_chars, char) then
        start_timer()
    end
end

local function validate_settings()
    assert(type(settings.mapping) == "table", "Mapping must be a table.")

    for _, mapping in ipairs(settings.mapping) do
        assert(#mapping == 2, "Mapping must be 2 keys.")
    end

    if settings.timeout then
        assert(type(settings.timeout) == "number", "Timeout must be a number.")
        assert(settings.timeout >= 100, "Timeout must be greater than 100.")
    end

    assert(
        vim.tbl_contains({ "string", "function" }, type(settings.keys)),
        "Keys must be a function or string."
    )
end

function M.setup(update)
    settings = vim.tbl_deep_extend("force", settings, update or {})
    -- if mapping is a string (single mapping) make it a table
    if type(settings.mapping) == "string" then
        settings.mapping = { settings.mapping }
    end
    local ok, msg = pcall(validate_settings)
    if ok then
        -- create tables with the first and seconds chars of the mappings
        for _, shortcut in ipairs(settings.mapping) do
            vim.cmd("silent! iunmap " .. shortcut)
            table.insert(first_chars, (string.sub(shortcut, 1, 1)))
            table.insert(second_chars, (string.sub(shortcut, 2, 2)))
        end

        vim.cmd([[
          augroup better_escape
          autocmd!
          autocmd InsertCharPre * lua require"better_escape".check_charaters()
          augroup END
        ]])
    else
        vim.notify("Error(better-escape.nvim): " .. msg, vim.log.levels.ERROR)
    end
end

return setmetatable(M, {
    __index = function(_, k)
        if k == "waiting" then
            return waiting
        end
    end,
})
