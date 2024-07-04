local M = {}
local uv = vim.uv
local function t(str)
    if vim.keycode then
        return vim.keycode(str)
    else
        return vim.api.nvim_replace_termcodes(str, true, true, true)
    end
end

M.waiting = false

local settings = {
    timeout = vim.o.timeoutlen,
    mappings = {
        i = {
            j = {
                k = "<Esc>",
                j = "<Esc>",
            },
        },
        c = {
            j = {
                k = "<Esc>",
                j = "<Esc>",
            },
        },
        t = {
            j = {
                k = "<Esc>",
                j = "<Esc>",
            },
        },
        v = {
            j = {
                k = "<Esc>",
            },
        },
        s = {
            j = {
                k = "<Esc>",
            },
        },
    },
}

local function clear_mappings()
    for mode, keys in pairs(settings.mappings) do
        for key, subkeys in pairs(keys) do
            vim.keymap.del(mode, key)
            for subkey, _ in pairs(subkeys) do
                vim.keymap.del(mode, subkey)
            end
        end
    end
end

-- WIP: move this into recorder.lua ?
local last_key = nil
local bufmodified = false
local sequence_timer = uv.new_timer()
local recorded_key = false
local function log_key(key)
    bufmodified = vim.bo.modified
    last_key = key
    recorded_key = true
    sequence_timer:stop()
    M.waiting = true
    sequence_timer:start(settings.timeout, 0, function()
        M.waiting = false
        if last_key == key then
            last_key = nil
        end
    end)
end

vim.on_key(function(mappings, typed)
    if typed == "" then
        return
    end
    if recorded_key then
        recorded_key = false
        return
    end
    last_key = nil
end)

-- list of modes that press <backspace> when escaping
local undo_key = {
    i = "<bs>",
    c = "<bs>",
    t = "<bs>",
    v = "",
    s = "",
}
local parent_keys = {}

local function map_keys()
    parent_keys = {}
    for mode, keys in pairs(settings.mappings) do
        for key, subkeys in pairs(keys) do
            vim.keymap.set(mode, key, function()
                log_key(key)
                vim.api.nvim_feedkeys(t(key), "in", false)
            end)
            for subkey, mapping in pairs(subkeys) do
                if mapping then
                    if not parent_keys[mode] then
                        parent_keys[mode] = {}
                    end
                    if not parent_keys[mode][subkey] then
                        parent_keys[mode][subkey] = {}
                    end
                    parent_keys[mode][subkey][key] = true
                    vim.keymap.set(mode, subkey, function()
                        -- In case the subkey happens to also be a starting key
                        if last_key == nil then
                            log_key(subkey)
                            vim.api.nvim_feedkeys(t(subkey), "in", false)
                            return
                        end
                        -- Make sure we are in the correct sequence
                        if not parent_keys[mode][subkey][last_key] then
                            vim.api.nvim_feedkeys(t(subkey), "in", false)
                            return
                        end
                        vim.api.nvim_feedkeys(
                            t(undo_key[mode] or ""),
                            "in",
                            false
                        )
                        vim.api.nvim_feedkeys(
                            t("<cmd>setlocal %smodified<cr>"):format(
                                bufmodified and "" or "no"
                            ),
                            "in",
                            false
                        )
                        if type(mapping) == "string" then
                            vim.api.nvim_input(mapping)
                        elseif type(mapping) == "function" then
                            mapping()
                        end
                    end)
                end
            end
        end
    end
end

function M.setup(update)
    settings = vim.tbl_deep_extend("force", settings, update or {})
    if settings.keys or settings.clear_empty_lines then
        vim.notify(
            "[better-escape.nvim]: Rewrite! Check: https://github.com/max397574/better-escape.nvim",
            vim.log.levels.WARN,
            {}
        )
    end
    if settings.mapping then
        vim.notify(
            "[better-escape.nvim]: Rewrite! Check: https://github.com/max397574/better-escape.nvim",
            vim.log.levels.WARN,
            {}
        )
        if type(settings.mapping) == "string" then
            settings.mapping = { settings.mapping }
        end
        for _, mapping in ipairs(settings.mappings) do
            settings.mappings.i[mapping:sub(1, 2)] = {}
            settings.mappings.i[mapping:sub(1, 1)][mapping:sub(2, 2)] =
                settings.keys
        end
    end
    pcall(clear_mappings)
    map_keys()
end

return M
