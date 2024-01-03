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
    },
    clear_empty_lines = false,
    ---@type string|function
    keys = "<Esc>",
}

local created_mappings = {}
local function clear_mappings()
    for _, key in ipairs(created_mappings) do
        pcall(vim.keymap.del, "i", key)
    end
end

local function check_charatcers()
    local char = vim.v.char
    local modified = vim.bo.modified
    if settings.mappings.i[char] then
        for key, mapping in pairs(settings.mappings.i[char]) do
            vim.keymap.set("i", key, function()
                pcall(vim.keymap.del, "i", key)
                clear_mappings()
                vim.api.nvim_input("<bs>")
                if type(mapping) == "string" then
                    vim.api.nvim_input(mapping)
                else
                    mapping()
                end
                vim.bo.modified = modified
            end)
            table.insert(created_mappings, key)
            vim.defer_fn(function()
                pcall(vim.keymap.del, "i", key)
            end, settings.timeout)
        end
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
    vim.api.nvim_create_autocmd("InsertCharPre", {
        callback = function()
            check_charatcers()
        end,
        group = vim.api.nvim_create_augroup("better_escape", {}),
    })
end

return M
