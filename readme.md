# 🚪better-escape.nvim

This is a lua version of
[better_escape.vim](https://github.com/jdhao/better-escape.vim)

✨Features
--------
* Escape without getting delay when typing in insert mode
* Customizable mapping and timeout
* Use multiple mappings
* Really small and fast

📦Installation
------------
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

⚙️Customization
-------------
Call the setup function with your options as arguments.

```lua
-- lua, default settings
require("better_escape").setup {
    mapping = {"jk", "jj"}, -- a table with mappings to use
    timeout = vim.o.timeoutlen, -- the time in which the keys must be hit in ms. Use option timeoutlen by default
    clear_empty_lines = false, -- clear line after escaping if there is only whitespace
    keys = "<Esc>", -- keys used for escaping, if it is a function will use the result everytime
    -- example
    -- keys = function()
    --   return vim.fn.col '.' - 2 >= 1 and '<esc>l' or '<esc>'
    -- end,
}
```

👀Demo
------

![mapping](https://user-images.githubusercontent.com/81827001/135870002-07c1dc41-f3e7-4ece-af6f-50e9b0711a66.gif)

![plugin](https://user-images.githubusercontent.com/81827001/135870101-febf3507-9327-4b80-aa9a-ba08bff6b8d4.gif)
