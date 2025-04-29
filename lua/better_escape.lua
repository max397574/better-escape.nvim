local M = {}
local uv = vim.uv or vim.loop
local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
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
                k = "<C-c>",
                j = "<C-c>",
            },
        },
        t = {
            j = {
                k = "<C-\\><C-n>",
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

-- WIP: move this into recorder.lua ?
local recorded_keys = ""
local bufmodified = nil
local timeout_timer = uv.new_timer()
local has_recorded = false -- See `vim.on_key` below
local function record_key(key)
    if timeout_timer:is_active() then
        timeout_timer:stop()
    end
    bufmodified = vim.bo.modified
    recorded_keys = recorded_keys .. key
    has_recorded = true
    M.waiting = true
    timeout_timer:start(settings.timeout, 0, function()
        M.waiting = false
        recorded_keys = ""
    end)
end

vim.on_key(function(_, typed)
    if typed == "" then
        return
    end
    if has_recorded == false then
        -- If the user presses a key that doesn't get recorded, remove the previously recorded key sequence.
        recorded_keys = ""
        return
    end
    has_recorded = false
end)

-- List of keys that undo the effect of pressing first_key
local undo_key = {
    i = "<bs>",
    c = "<bs>",
    t = "<bs>",
}
-- hash map with all mapped keys
local mapped_keys = {}
-- A thin wrapper around vim.keymap.set to record every mapped key
local function map(mode, keys, action, opts)
    if not mapped_keys[mode] then
        mapped_keys[mode] = {}
    end
    mapped_keys[mode][keys] = true
    vim.keymap.set(mode, keys, action, opts)
end

local parent_tree = {}
local function map_final(mode, key, parents, action)
    if not parent_tree[mode] then
        parent_tree[mode] = {}
    end
    if not parent_tree[mode][key] then
        parent_tree[mode][key] = {}
    end
    -- Handle the first sequence
    if #parent_tree[mode][key] == 0 then
        -- We store the parents sequences and actions in an array because we need the parents to be sorted
        -- By longest to shortest, because a longer sequence could contain a shorter sequence (jjk & jk)
        -- Example:
        -- parents = jk, jjk
        -- recorded_keys = "anythingjjk"
        -- if the plugin compares the end of recorded_keys to "jk" first,
        -- it would use "jk"'s action since the recorded_keys end in "jk",
        -- so it would miss that the recorded_keys actually end in the "jjk" sequence
        table.insert(parent_tree[mode][key], { parents, action })
        map(mode, key, function()
            if recorded_keys == "" then
                record_key(key)
                return key
            end
            local action = nil
            local parent_length = 0
            for _, v in ipairs(parent_tree[mode][key]) do
                -- compare the end of recorded_keys to every parent sequence
                if v[1] == recorded_keys:sub(- #v[1]) then
                    parent_length = #v[1]
                    action = v[2]
                    break
                end
            end
            -- no parent sequence was found
            if not action then
                record_key(key)
                return key
            end
            if action == "" then
                return key
            end
            local keys = ""
            keys = keys
                .. t(
                    (undo_key[mode] or ""):rep(parent_length)
                    .. (
                        ("<cmd>setlocal %smodified<cr>"):format(
                            bufmodified and "" or "no"
                        )
                    )
                )
            if type(action) == "string" then
                keys = keys .. t(action)
            elseif type(action) == "function" then
                keys = keys .. t(action() or "")
            end
            vim.api.nvim_feedkeys(keys, "in", false)
        end, { expr = true })
    end
    -- Handle new sequences
    -- sort the tree while inserting
    for i, v in ipairs(parent_tree[mode][key]) do
        -- prioritize longer sequences over shorter ones (jjk > jk)
        if #parents >= #v[1] then
            table.insert(parent_tree[mode][key], i, { parents, action })
            return
        end
    end
    -- the new parent sequence is smaller than all other parents
    -- so add it at the last spot
    table.insert(parent_tree[mode][key], { parents, action })
end

local function map_parent(mode, key)
    -- Don't overwrite a final mapping
    if parent_tree[mode] and parent_tree[mode][key] then
        return
    end
    -- Don't map the same key 2 times
    if mapped_keys[mode] and mapped_keys[mode][key] then
        return
    end
    map(mode, key, function()
        record_key(key)
        return key
    end, { expr = true })
end

local disabled_mappings = {}
local function disable_keys()
    for mode, first_keys in pairs(settings.mappings) do
        disabled_mappings[mode] = {}
        function parse_keys(mode, keys, parents)
            for k, v in pairs(keys) do
                local sub_parents = parents .. k
                if type(v) == "table" then
                    -- Handle subkeys
                    parse_keys(mode, v, sub_parents)
                else
                    if v == false then
                        disabled_mappings[mode][sub_parents] = true
                    end
                end
            end
        end

        parse_keys(mode, first_keys, "")
    end
end

local function map_keys()
    for mode, first_keys in pairs(settings.mappings) do
        local function recursive_map(mode, keys, parents)
            for k, v in pairs(keys) do
                -- Handle multiple characters in a table
                -- (e.g i = { jjk = "<Esc>" })
                -- consider every key except the last as a parent ("jj" in the example above)
                -- and map them
                local sub_parents = parents .. (k:sub(1, #k - 1) or "")
                for i = 1, #k - 1, 1 do
                    local key = k:sub(i, i)
                    map_parent(mode, key)
                end
                k = k:sub(#k, #k)

                if type(v) == "table" then
                    -- Handle subkeys
                    sub_parents = sub_parents .. k
                    recursive_map(mode, v, sub_parents)
                    map_parent(mode, k)
                else
                    if disabled_mappings[mode][sub_parents .. k] then
                        keys[k] = nil
                    else
                        -- No more subkeys, map the final key
                        map_final(mode, k, sub_parents, v)
                    end
                end
            end
        end
        recursive_map(mode, first_keys, "")
    end
end

local function unmap_keys()
    for mode, keys in pairs(mapped_keys) do
        for key, _ in pairs(keys) do
            pcall(vim.keymap.del, mode, key)
        end
    end
    mapped_keys = {}
    parent_tree = {}
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
    disable_keys()
    unmap_keys()
    map_keys()
end

return M
