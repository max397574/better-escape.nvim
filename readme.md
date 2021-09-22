# 🚪better-escape.nvim

This is a lua version of
[better_escape.vim](https://github.com/jdhao/better-escape.vim)

✨Features
--------
* Escape without getting delay when typing in insert mode
* Customizable mapping and timeout

📦Installation
------------
Use your favourite package manager and call setup function.
```vim
" Vimscript with vim-plug
Plug 'max397574/better-escape.nvim'
lua require("betterEscape_nvim").init()
```

```lua
-- lua with packer.nvim
use {
  "max397574/better-escape.nvim",
  config = function()
    require("betterEscape_nvim").init()
  end,
}
```

✅Usage
-----
Just use your mapping.

⚙️Customization
-------------
Call the setup function before calling the init function.

```lua
-- lua, default settings
require("betterEscape_nvim").setup {
    mapping = "jk" -- the mapping to escape
    timeout = 200 -- the time in which the keys must be hit in ms
}
```

```vim
-- Vimscript, default settings
lua << EOF
require("betterEscape_nvim").setup {
    mapping = "jk" -- the mapping to escape
    timeout = 200 -- the time in which the keys must be hit in ms
}
EOF
```

🚫Limitations/Issues
--------------------
* Currently doesn't work with mappings which have the same letter e.g. jj.
* Doesn't work if one of the keys of the mapping is mapped to something else.

💡Future Plans/Ideas
------------------
Fix the limitations.

👀Demo
------

When using `inoremap jk <ESC>`:

https://user-images.githubusercontent.com/81827001/134317521-0c446238-c24c-4303-9539-e5eb6236d221.mp4

When using this plugin:

https://user-images.githubusercontent.com/81827001/134317540-95a66237-dd77-49a9-8f11-8b037458354c.mp4

