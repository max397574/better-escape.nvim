# better-escape.nvim

![better-escape](https://github.com/max397574/better-escape.nvim/assets/81827001/8863a620-b075-4417-92d0-7eb2d2646186)

A lot of people have mappings like `jk` or `jj` to escape insert mode. The
problem with this mappings is that whenever you type a `j`, neovim wait about
100-500ms (depending on your timeoutlen) to see, if you type a `j` or a `k`
because these are mapped. Only after that time the `j` will be inserted. Then
you always get a delay when typing a `j`.

An example where this has a big impact is e.g. telescope. Because the characters
which are mapped aren't really inserted at first the whole filtering isn't
instant.

![better-escape-tele](https://github.com/max397574/better-escape.nvim/assets/81827001/390f115d-87cd-43d8-aadf-fffb12bd84c9)

## ✨Features

- Write mappings in many modes without having a delay when typing
- Customizable timeout
- Map key sequences and lua functions
- Use multiple mappings
- Really small and fast

## 📦Installation

Use your favourite package manager and call the setup function.

```lua
-- lua with lazy.nvim
{
  "max397574/better-escape.nvim",
  config = function()
    require("better_escape").setup()
  end,
}
```

## ❗Rewrite

There was a big rewrite which allows much more flexibility now. You can now
define mappings in most modes and also use functions.

The biggest change was that the `mapping` config option was removed. Check the
default configuration below to see the new structure.

This also deprecated the `clear_empty_lines` setting. You can replicate this
behavior by setting a mapping to a function like this:

```lua
-- `k` would be the second key of a mapping
k = function()
    vim.api.nvim_input("<esc>")
    local current_line = vim.api.nvim_get_current_line()
    if current_line:match("^%s+j$") then
        vim.schedule(function()
            vim.api.nvim_set_current_line("")
        end)
    end
end
```
## Default configuration

To disable all default mappings set the `default_mappings` option to false.   
To disable specific mappings set their key to `false` in the configuration. There's an example in the Customization section.

```lua
-- lua, default settings
require("better_escape").setup {
    timeout = vim.o.timeoutlen, -- after `timeout` passes, you can press the escape key and the plugin will ignore it
    default_mappings = true, -- setting this to false removes all the default mappings
    mappings = {
        -- i for insert
        i = {
            j = {
                -- These can all also be functions
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
```
## ⚙️Customization

Call the setup function with your options as arguments:
```lua
require("better_escape").setup {
    timeout = vim.o.timeoutlen, -- after `timeout` passes, you can press the escape key and the plugin will ignore it
    default_mappings = true, -- setting this to false removes all the default mappings
    mappings = {
        -- mode = {
        --     firstkey = {
        --        secondkey = "Escape key", -- make a key press "Escape key"
        --        secondkey = false, -- disable a key
        --     },
        -- }
    }
}
```

Here how you can configure Insert-mode:
```lua
mappings = {
    -- i for insert, other modes are the first letter too
    i = {
        -- map kj to exit insert mode
        k = {
            j = "<Esc>",
        },
        -- map jk and jj  to exit insert mode
        j = {
            k = "<Esc>",
            j = "<Esc>",
        },
        -- disable jj
        j = {
            j = false,
        },
    }
}
```

You can also use a function instead of keys. So you could for example map
`<space><tab>` to jump with luasnip like this:

```lua
i = {
    [" "] = {
        ["<tab>"] = function()
            -- Defer execution to avoid side-effects
            vim.defer_fn(function()
                -- set undo point
                vim.o.ul = vim.o.ul
                require("luasnip").expand_or_jump()
            end, 1)
        end
    }
}
```

## API

`require("better_escape").waiting` is a boolean indicating that it's waiting for
a mapped sequence to complete.

```lua
function escape_status()
  local ok, m = pcall(require, 'better_escape')
  return ok and m.waiting and '✺' or ""
end
```

## ❤️ Support

If you like the projects I do and they can help you in your life you can support
my work with [github sponsors](https://github.com/sponsors/max397574). Every
support motivates me to continue working on my open source projects.

## Similar plugins

The old version of this plugin was a lua version of
[better_escape.vim](https://github.com/jdhao/better-escape.vim), with some
additional features and optimizations. This changed with the rewrite though. Now
it has much more features.
