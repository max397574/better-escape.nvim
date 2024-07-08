local M = {}
local uv = vim.uv

M.waiting = false

local settings = {
    timeout = vim.o.timeoutlen,
    mappings = {
        i = {
        --  startkey[s]
            j = {
            --  endkey[s]
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
local recorded_key = nil -- When a startkey is pressed, `recorded_key` is set to it (e.g. if jk is a mapping, when 'j' is pressed, `recorded_key` is set to 'j')
local bufmodified = false
local timeout_timer = uv.new_timer()
local has_recorded = false -- See `vim.on_key` below
local function record_key(key)
    timeout_timer:stop()
    bufmodified = vim.bo.modified
    recorded_key = key
    has_recorded = true 
    M.waiting = true
    timeout_timer:start(settings.timeout, 0, function()
        M.waiting = false
        recorded_key = nil
    end)
end

vim.on_key(function()
    if has_recorded == false then
        -- If the user presses a key that doesn't get recorded, remove the previously recorded key.
        recorded_key = nil
        return
    end
    has_recorded = false
end)

-- List of keys that undo the effect of pressing startkey
local undo_key = {
    i = "<bs>",
    c = "<bs>",
    t = "<bs>",
}

local sequences = {
    -- Stores a sequence with this layout: mode[s] = { endkey[s] = { startkey[s] } } 
}
local function map_keys()
    sequences = {}
    for mode, startkeys in pairs(settings.mappings) do
        local map_opts = { expr = true }
        for startkey, _ in pairs(startkeys) do
            vim.keymap.set(mode, startkey, function()
                record_key(startkey)
                return startkey
            end, map_opts)
        end
        for startkey, endkeys in pairs(startkeys) do
            for endkey, mapping in pairs(endkeys) do
                if not mapping then
                    goto continue
                end
                if not sequences[mode] then
                    sequences[mode] = {}
                end
                if not sequences[mode][endkey] then
                    sequences[mode][endkey] = {}
                end
                sequences[mode][endkey][startkey] = true
                vim.keymap.set(mode, endkey, function()
                    -- If a startkey wasn't recorded, record endkey because it might be a startkey for another sequence.
                    -- TODO: Explicitly, check if it's a starting key. I don't think that's necessary right now.
                    if recorded_key == nil then
                        record_key(endkey)
                        return endkey
                    end
                    -- If a key was recorded, but it isn't the startkey for endkey, record endkey(endkey might be a startkey for another sequence)
                    if not sequences[mode][endkey][recorded_key] then
                        record_key(endkey)
                        return endkey
                    end
                    vim.api.nvim_input(undo_key[mode] or "")
                    vim.api.nvim_input(
                        ("<cmd>setlocal %smodified<cr>"):format(
                            bufmodified and "" or "no"
                        )
                    )
                    if type(mapping) == "string" then
                        vim.api.nvim_input(mapping)
                    elseif type(mapping) == "function" then
                        vim.api.nvim_input(mapping() or "")
                    end
                end, map_opts)
                ::continue::
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
