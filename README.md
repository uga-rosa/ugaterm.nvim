# ugaterm.nvim

A terminal plugin for Neovim.

# Setup

```lua
require("ugaterm").setup({
  prefix = "ugaterm",
  filetype = "ugaterm",
  open_cmd = "botright 15sp",
  capacity = 10,
})
```

# Commands

- UgatermOpen
  - Open most recently used terminal.
  - If the terminal has never been opened, UgatermNew is called.
- UgatermNew
  - Open a new terminal.
- UgatermClose
  - Close a terminal window.
- UgatermToggle
  - Toggle a terminal window.
- UgatermSelect
  - Select a terminal using vim.ui.select().
- UgatermRename
  - Rename a current terminal buffer.
