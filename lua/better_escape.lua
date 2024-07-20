local M = {}
local uv = vim.uv or vim.loop
local nvim_version = vim.version().minor
local has_v0_10 = nvim_version >= 10
local t = vim.keycode
    or function(keys)
        return vim.api.nvim_replace_termcodes(keys, true, true, true)
    end

M.waiting = false

local settings = {
    timeout = vim.o.timeoutlen,
    default_mappings = true,
    mappings = {
        i = {
            --  first_key[s]
            j = {
                --  second_key[s]
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

local function unmap_keys()
    for mode, keys in pairs(settings.mappings) do
        for key, subkeys in pairs(keys) do
            pcall(vim.keymap.del, mode, key)
            for subkey, _ in pairs(subkeys) do
                pcall(vim.keymap.del, mode, subkey)
            end
        end
    end
end

-- WIP: move this into recorder.lua ?
-- When a first_key is pressed, `recorded_key` is set to it
-- (e.g. if jk is a mapping, when 'j' is pressed, `recorded_key` is set to 'j')
local recorded_key = nil
local bufmodified = nil
local timeout_timer = uv.new_timer()
local has_recorded = 0 -- This variable is how many keys are considered recorded.
local function record_key(key)
    if timeout_timer:is_active() then
        timeout_timer:stop()
    end
    bufmodified = vim.bo.modified
    recorded_key = key
    -- Consider 2 keys recorded for < v0.10 versions because `vim.on_key` is called 2 times--once with the second parameter as "<first_key>",
    -- and another time with the 2nd parameter as ""(nothing)--It's called a 2nd time because better-escape uses `feedkeys` to press the key after the `first_key`'s mapping is evaluated.
    -- > v0.10 versions don't need a second record because they avoid handling keys that come from `feedkeys`.
    has_recorded = has_v0_10 and 1 or 2
    M.waiting = true
    timeout_timer:start(settings.timeout, 0, function()
        M.waiting = false
        recorded_key = nil
    end)
end

vim.on_key(function(_, typed)
    if typed == "" then
        return
    end
    if has_recorded == 0 then
        -- If the user presses a key that doesn't get recorded, remove the previously recorded key.
        recorded_key = nil
        return
    end
    has_recorded = has_recorded - 1
end)

-- List of keys that undo the effect of pressing first_key
local undo_key = {
    i = "<bs>",
    c = "<bs>",
    t = "<bs>",
}

local function map_keys()
    for mode, first_keys in pairs(settings.mappings) do
        for first_key, _ in pairs(first_keys) do
            vim.keymap.set(mode, first_key, function()
                record_key(first_key)
                -- Use feedkeys instead of expr-mappings to avoid expr-mapping's limitations--such as not being able to modify the buffer because of `textlock`. See `:h :map-expression`
                vim.api.nvim_feedkeys(t(first_key), "in", false)
            end)
        end
        for _, second_keys in pairs(first_keys) do
            for second_key, mapping in pairs(second_keys) do
                if not mapping then
                    goto continue
                end
                vim.keymap.set(mode, second_key, function()
                    -- If a first_key wasn't recorded, record second_key because it might be a first_key for another sequence.
                    -- TODO: Explicitly, check if it's a starting key. I don't think that's necessary right now.
                    if recorded_key == nil then
                        record_key(second_key)
                        vim.api.nvim_feedkeys(t(second_key), "in", false)
                        return
                    end
                    -- If a key was recorded, but it isn't the first_key for second_key, record second_key(second_key might be a first_key for another sequence)
                    -- Or if the recorded_key was just a second_key
                    if
                        not (
                            first_keys[recorded_key]
                            and first_keys[recorded_key][second_key]
                        )
                    then
                        record_key(second_key)
                        vim.api.nvim_feedkeys(t(second_key), "in", false)
                        return
                    end
                    vim.api.nvim_feedkeys(
                        vim.api.nvim_replace_termcodes(
                            undo_key[mode] or "",
                            true,
                            false,
                            true
                        ),
                        "n",
                        false
                    )
                    vim.api.nvim_input(
                        ("<cmd>setlocal %smodified<cr>"):format(
                            bufmodified and "" or "no"
                        )
                    )
                    if type(mapping) == "string" then
                        vim.api.nvim_feedkeys(
                            vim.api.nvim_replace_termcodes(
                                mapping,
                                true,
                                false,
                                true
                            ),
                            "n",
                            false
                        )
                    elseif type(mapping) == "function" then
                        vim.api.nvim_feedkeys(
                            vim.api.nvim_replace_termcodes(
                                mapping() or "",
                                true,
                                false,
                                true
                            ),
                            "n",
                            false)
                    end
                end)
                ::continue::
            end
        end
    end
end

function M.setup(update)
    if update and update.default_mappings == false then
        settings.mappings = {}
    end
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
    unmap_keys()
    map_keys()
end

return M
