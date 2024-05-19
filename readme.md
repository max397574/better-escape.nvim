# 🚪better-escape.nvim

## Origin
This plugin originally was a lua version of [better_escape.vim](https://github.com/jdhao/better-escape.vim),
with some additional features and optimizations.

A lot of people have mappings like `jk` or `jj` to escape insert mode.
The problem with this mappings is that whenever you type a `j`, neovim waits about 100-500ms (depending on your timeoutlen) to see, if you type a `j` or a `k` because these are mapped.
Only after that time the `j` will be inserted.
Then you always get a delay when typing a `j`.

This looks like this (see below for a gif):

![Screen Shot 2021-10-08 at 16 21 23](https://user-images.githubusercontent.com/81827001/136576543-c8b4e802-84a8-4087-a7a4-f7d069931885.png)

This plugin allows to create mappings in insert mode without having that delay.

Additionally also command line mappings were added.

## ✨Features

- Insert and command mode mappings
- Customizable timeout
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

## ⚙️Customization
Call the setup function with your options as arguments.
```lua
-- lua, default settings
require("better_escape").setup {
    -- the time in which the keys must be hit in ms. Use option timeoutlen by default
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
    },
}
```

You can also use functions like this:
```lua
mappings = {
    i = {
        [" "] = {
            ["<TAB>"] = function()
                require("luasnip").expand_or_jump()
            end,
        }
    }
}
```
## 👀Demo

![mapping](https://user-images.githubusercontent.com/81827001/135870002-07c1dc41-f3e7-4ece-af6f-50e9b0711a66.gif)

![plugin](https://user-images.githubusercontent.com/81827001/135870101-febf3507-9327-4b80-aa9a-ba08bff6b8d4.gif)

## 🎓How it works
The plugin checks for keypresses in the used modes with an autocommand. If the key pressed is the first of one of the mappings
the plugin will create a mappings for the second key which automatically is deleted again after the specified delay or if it's triggered.

## ❤️ Support
If you like the projects I do and they can help you in your life you can support my work with [github sponsors](https://github.com/sponsors/max397574).
Every support motivates me to continue working on my open source projects.
