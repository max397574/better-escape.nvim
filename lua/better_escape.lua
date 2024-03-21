local M = {}
local uv = vim.uv

local settings = {
    timeout = vim.o.timeoutlen,
    -- deprecated
    -- mapping = nil,
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
                -- WIP: is this a good idea for visual mode?
                --    j = "<Esc>",
            },
        },
        s = {
            j = {
                k = "<Esc>",
            },
        },
        n = {
            j = {
                k = "<Esc>",
            },
        },
    },
    -- WIP: still not added in the pr,
    -- i feel like this option should be removed and a method to get the behaviour with the old should be added to the readme
    clear_empty_lines = false,
    -- deprecated
    ---@type string|function
    -- keys = "<Esc>",
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
    sequence_timer:start(settings.timeout, 0, function()
        if last_key == key then
            last_key = nil
        end
    end)
end

vim.on_key(function()
    if recorded_key then
        recorded_key  = false
        return
    end
    -- make sure to only store a sequence when a key is actually pressed
    last_key = nil
end)

-- list of modes that press <backspace> when escaping
local undo_key = {
    i = "<bs>",
    c = "<bs>",
    t = "<bs>",
    v = "",
    n = "",
    s = "",
    o = "",
}
local parent_keys = {}
local function map_keys()
    parent_keys = {}
    for mode, keys in pairs(settings.mappings) do
        local map_opts = { expr = true }
        if mode == "o" then
            -- WIP: got any ideas?
            -- i can't just map keys because you can't easily undo every motion i think
            -- and you can't press 2 operators at the same time you would have to leave operator pending mode
            vim.notify(
                "[better-escape.nvim]: operator-pending mode is not supported yet as it needs discussion",
                vim.log.levels.WARN,
                {}
            )
            goto continue
        end
        for key, subkeys in pairs(keys) do
            vim.keymap.set(mode, key, function()
                log_key(key)
                return key
            end, map_opts)
            for subkey, mapping in pairs(subkeys) do
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
                        return subkey
                    end
                    -- Make sure we are in the correct sequence
                    if not parent_keys[mode][subkey][last_key] then
                        return subkey
                    end
                    vim.api.nvim_input(undo_key[mode] or "")
                    vim.api.nvim_input(
                        ("<cmd>setlocal %smodified<cr>"):format(
                            bufmodified and "" or "no"
                        )
                    )
                    if type(mapping) == "string" then
                        vim.api.nvim_input(mapping)
                    else
                        local user_keys = mapping()
                        if type(user_keys) == "string" then
                            vim.api.nvim_input(user_keys)
                        end
                    end
                end, map_opts)
            end
        end
        ::continue::
    end
end

function M.setup(update)
    settings = vim.tbl_deep_extend("force", settings, update or {})
    if settings.mapping then
        vim.notify(
            "[better-escape.nvim]: config.mapping is deprecated, use config.mappings instead (check readme)",
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
