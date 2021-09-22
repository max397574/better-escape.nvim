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
Plug 'max397574/footprints.nvim'
lua require("betterEscape_nvim").init()
```

```lua
-- lua with packer.nvim
use {
  "max397574/footprints.nvim",
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
```lua
-- lua, default settings
require("betterEscape_nvim").setup {
    settings.mapping = "jk"
    settings.timeout = "200"
}
```

```vim
-- Vimscript, default settings
lua << EOF
require("betterEscape_nvim").setup {
    settings.mapping = "jk"
    settings.timeout = "200"
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
