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
- UgatermHide
  - Hide a terminal window.
- UgatermToggle
  - Toggle a terminal window (open/hide).
- UgatermSelect
  - Select a terminal using vim.ui.select().
- UgatermDelete
  - Delete a current terminal buffer.
  - If there are other terminals, open more recently used one.
  - If it is the last one, close the window too.
- UgatermRename
  - Rename a current terminal buffer.
