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

- Escape without getting delay when typing in insert mode
- Customizable mapping and timeout
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

## ⚙️Customization

Call the setup function with your options as arguments.

```lua
-- lua, default settings
require("better_escape").setup {
    mapping = {"jk", "jj"}, -- a table with mappings to use
    timeout = vim.o.timeoutlen, -- the time in which the keys must be hit in ms. Use option timeoutlen by default
    clear_empty_lines = false, -- clear line after escaping if there is only whitespace
    keys = "<Esc>", -- keys used for escaping, if it is a function will use the result everytime
    -- example(recommended)
    -- keys = function()
    --   return vim.api.nvim_win_get_cursor(0)[2] > 1 and '<esc>l' or '<esc>'
    -- end,
}
```

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

## 🎓How it works

With the mappings there are two tables created.
One contains all first characters and one all second characters.
Whenever you type a character the plugin checks if it's in any of the two tables
If it is in the first one, the plugin starts a timer.
If it is in the second, the plugin checks whether the character you typed before is in the table with the first characters.

If this is the case the plugin gets all the indices where the characters are in the tables, then is searches for matches.
If there is a match, that means that there is a mapping which has the typed character as second and the previous typed character as first character.
The plugin then checks if the time passed since the first character was types is smaller than `timoutlen`.
If this is the case the two characters get deleted and `keys` get feed or executed.

Like this it is possible that the characters really get inserted and therefore you have no delay after typing one of the characters of your mapping.
With the `timeoutlen` it's still possible to type the characters of your mappings.
