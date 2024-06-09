# 🚪better-escape.nvim

This plugin is the lua version of [better_escape.vim](https://github.com/jdhao/better-escape.vim),
with some additional features and optimizations

A lot of people have mappings like `jk` or `jj` to escape insert mode.
The problem with this mappings is that whenever you type a `j`, neovim wait about 100-500ms (depending on your timeoutlen) to see, if you type a `j` or a `k` because these are mapped.
Only after that time the `j` will be inserted.
Then you always get a delay when typing a `j`.

This looks like this (see below for a gif):

![Screen Shot 2021-10-08 at 16 21 23](https://user-images.githubusercontent.com/81827001/136576543-c8b4e802-84a8-4087-a7a4-f7d069931885.png)

## ✨Features

- Escape without getting delay when typing from different modes
- Customizable timeout
- Map key sequences and lua functions
- Use multiple mappings
- Really small and fast

## 📦Installation

Use your favourite package manager and call the setup function.

```lua
-- lua with packer.nvim
use {
  "max397574/better-escape.nvim",
  config = function()
    require("better_escape").setup()
  end,
}
```

## ❗Rewrite
There was a big rewrite which allows much more flexibility now.
You can now define mappings in most modes and also use functions.

The biggest change was that the `mapping` config option was removed.
Check the default configuration below to see the new structure.

This also deprecated the `clear_empty_lines` setting.
You can replicate this behavior with a function like this:
```lua
k = function()
    vim.api.nvim_input("<esc>")
    local current_line = vim.api.nvim_get_current_line()
    if current_line:match("^%s+j$") then
        vim.schedule(function()
            vim.api.nvim_set_current_line("")
        end
    end
end
```

## ⚙️Customization

Call the setup function with your options as arguments.

<details>
<summary>Default Config</summary>

```lua
-- lua, default settings
require("better_escape").setup {
    timeout = vim.o.timeoutlen,
    mappings = {
        i = {
            j = {
                -- These can all also be functions
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
```
<details>

## API

`require("better_escape").waiting` is a boolean indicating that it's waiting for
a mapped sequence to complete.

<details>
<summary>statusline example</summary>

```lua
function escape_status()
  local ok, m = pcall(require, 'better_escape')
  return ok and m.waiting and '✺' or ""
end
```

</details>

## 👀Demo

![mapping](https://user-images.githubusercontent.com/81827001/135870002-07c1dc41-f3e7-4ece-af6f-50e9b0711a66.gif)

![plugin](https://user-images.githubusercontent.com/81827001/135870101-febf3507-9327-4b80-aa9a-ba08bff6b8d4.gif)

## ❤️ Support
If you like the projects I do and they can help you in your life you can support my work with [github sponsors](https://github.com/sponsors/max397574).
Every support motivates me to continue working on my open source projects.
