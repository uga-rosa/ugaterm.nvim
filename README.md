# ugaterm.nvim

A terminal plugin for Neovim.

![demo](https://user-images.githubusercontent.com/82267684/232364367-afd26d92-82e9-4f17-8604-560d9bf03824.gif)

# Setup

```lua
require("ugaterm").setup({
  ---@type string The terminal buffer name prefix.
  prefix = "ugaterm",
  ---@type string The filetype for a terminal buffer.
  filetype = "ugaterm",
  ---@type string|function Command|function to open a teminal window.
  open_cmd = "botright 15sp",
  -- Example of opening in a floating window.
  --
  -- open_cmd = function()
  --   local height = vim.api.nvim_get_option("lines")
  --   local width = vim.api.nvim_get_option("columns")
  --   vim.api.nvim_open_win(0, true, {
  --     relative = "editor",
  --     row = math.floor(height * 0.1),
  --     col = math.floor(width * 0.1),
  --     height = math.floor(height * 0.8),
  --     width = math.floor(width * 0.8),
  --   })
  -- end,
})
```

# Commands

- UgatermOpen
  - Open the most recently used terminal.
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
- UgatermRename [{newname}]
  - Rename a current terminal buffer.
  - If {newname} is omitted, use vim.ui.input().
