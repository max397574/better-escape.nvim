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
        -- If the user presses a key that doesn't get recorded, remove the previously recorded key.
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

local parent_tree = {}


local function map_final(mode, key, parents, action)
    if not parent_tree[mode] then
        parent_tree[mode] = {}
    end
    if not parent_tree[mode][key] then
        parent_tree[mode][key] = {}
    end
    -- sort the tree while inserting
    -- prioritize longer sequences over shorter ones (jjk > jk)
    for i, v in ipairs(parent_tree[mode][key]) do
        if #parents > #v[1] then
            table.insert(parent_tree[mode][key], i, { parents, action })
            break
        end
    end
    if #parent_tree[mode][key] == 0 then
        table.insert(parent_tree[mode][key], { parents, action })
    else
        -- don't map the key 2 times
        return
    end
    vim.keymap.set(mode, key, function()
        -- If a first_key wasn't recorded, record second_key because it might be a first_key for another sequence.
        -- TODO: Explicitly, check if it's a starting key. I don't think that's necessary right now.
        if recorded_keys == "" then
            record_key(key)
            return key
        end
        local action = nil
        for _, v in ipairs(parent_tree[mode][key]) do
            if v[1] == recorded_keys:sub(-#v[1]) then
                action = v[2]
                break
            end
        end
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
                (undo_key[mode] or "")
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

local function map_keys()
    for mode, keys_1 in pairs(settings.mappings) do
        local function recursive_map(mode, keys, parents)
            for k, v in pairs(keys) do
                if type(v) ~= "table" then
                    map_final(mode, k, parents, v)
                    goto continue
                end
                local sub_parents = parents .. k
                recursive_map(mode, v, sub_parents);
                if parent_tree[mode][k] then
                    goto continue
                end
                vim.keymap.set(mode, k, function()
                    record_key(k)
                    return k
                end, { expr = true })
                
                ::continue::
            end
        end
        recursive_map(mode, keys_1, "")
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
