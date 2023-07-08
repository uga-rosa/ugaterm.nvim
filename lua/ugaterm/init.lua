local config = require("ugaterm.config")
local ui = require("ugaterm.ui").new()

local M = {}

M.setup = config.set

function M.create_commands()
  vim.api.nvim_create_user_command("UgatermOpen", function()
    ui:open()
  end, {})
  vim.api.nvim_create_user_command("UgatermNew", function()
    ui:new_open()
  end, {})
  vim.api.nvim_create_user_command("UgatermNewWithName", function(opt)
    ui:new_open(opt.args)
  end, { nargs = "?" })
  vim.api.nvim_create_user_command("UgatermHide", function()
    ui:hide()
  end, {})
  vim.api.nvim_create_user_command("UgatermToggle", function()
    ui:toggle()
  end, {})
  vim.api.nvim_create_user_command("UgatermDelete", function()
    ui:delete()
  end, {})
  vim.api.nvim_create_user_command("UgatermSelect", function()
    ui:select()
  end, {})
  vim.api.nvim_create_user_command("UgatermRename", function(opt)
    ui:rename(opt.args)
  end, { nargs = "?" })
end

return M
