if vim.g.loaded_ugaterm then
  return
end
vim.g.loaded_ugaterm = true

require("ugaterm").create_commands()
