local config = require("ugaterm.config")
local terminal = require("ugaterm.terminal").new()

local M = {}

M.setup = config.set

function M.create_commands()
  vim.api.nvim_create_user_command("UgatermOpen", function()
    terminal:open()
  end, {})
  vim.api.nvim_create_user_command("UgatermNew", function()
    terminal:new_open()
  end, {})
  vim.api.nvim_create_user_command("UgatermSend", function(opt)
    terminal:send(opt.fargs[1], table.concat(opt.fargs, " ", 2))
  end, {
    nargs = "+",
    ---@param cmdline string
    ---@param cursor_pos integer
    ---@return string[]
    complete = function(_, cmdline, cursor_pos)
      if not cmdline:sub(1, cursor_pos):find("^UgatermSend%s+%S*$") then
        return {}
      end
      local items = {}
      for buf_cache in terminal.buf_cache:iter() do
        table.insert(items, buf_cache.bufname)
      end
      return items
    end,
  })
  vim.api.nvim_create_user_command("UgatermHide", function()
    terminal:hide()
  end, {})
  vim.api.nvim_create_user_command("UgatermToggle", function()
    terminal:toggle()
  end, {})
  vim.api.nvim_create_user_command("UgatermDelete", function()
    terminal:delete()
  end, {})
  vim.api.nvim_create_user_command("UgatermSelect", function()
    terminal:select()
  end, {})
  vim.api.nvim_create_user_command("UgatermRename", function(opt)
    terminal:rename(opt.args)
  end, { nargs = "?" })
end

return M
