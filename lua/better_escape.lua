local M = {}

local settings = {
    timeout = vim.o.timeoutlen,
    mapping = nil,
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
    },
    ---@type string|function
    keys = "<Esc>",
}

local created_mappings = { c = {}, i = {} }

local function clear_mappings(mode)
    for _, key in ipairs(created_mappings[mode]) do
        pcall(vim.keymap.del, mode, key)
    end
end

local function check_cmdline()
    local cmdline = vim.fn.getcmdline()
    if cmdline == nil then
        return
    end
    local char = cmdline:sub(-1)
    if settings.mappings.c[char] then
        for key, mapping in pairs(settings.mappings.c[char]) do
            vim.keymap.set("c", key, function()
                pcall(vim.keymap.del, "c", key)
                clear_mappings("c")
                vim.api.nvim_input("<bs>")
                if type(mapping) == "string" then
                    vim.api.nvim_input(mapping)
                else
                    mapping()
                end
            end, { nowait = true })
            table.insert(created_mappings.c, key)
            vim.defer_fn(function()
                pcall(vim.keymap.del, "c", key)
            end, settings.timeout)
        end
    else
        clear_mappings("c")
    end
end

local function check_charatcers_insert()
    local char = vim.v.char
    if settings.mappings.i[char] then
        for key, mapping in pairs(settings.mappings.i[char]) do
            vim.keymap.set("i", key, function()
                pcall(vim.keymap.del, "i", key)
                clear_mappings("i")
                vim.api.nvim_input("<bs>")
                if type(mapping) == "string" then
                    vim.api.nvim_input(mapping)
                else
                    mapping()
                end
            end)
            table.insert(created_mappings.i, key)
            vim.defer_fn(function()
                pcall(vim.keymap.del, "i", key)
            end, settings.timeout)
        end
    else
        clear_mappings("i")
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
    local augroup = vim.api.nvim_create_augroup("better_escape", {})
    vim.api.nvim_create_autocmd("InsertCharPre", {
        callback = function()
            check_charatcers_insert()
        end,
        group = augroup,
    })

    vim.api.nvim_create_autocmd("CmdLineChanged", {
        callback = function()
            check_cmdline()
        end,
        group = augroup,
    })
end

return M
