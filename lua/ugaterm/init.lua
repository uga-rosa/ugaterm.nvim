local terminal = require("ugaterm.terminal").new()

local M = {}

---@param opts TerminalOptions|nil
function M.setup(opts)
  opts = opts or {}
  vim.validate({
    opts = { opts, "t" },
    prefix = { opts.prefix, "s", true },
    filetype = { opts.prefix, "s", true },
    open_cmd = { opts.open_cmd, { "s", "c" }, true },
  })
  terminal:option_set(opts)
end

function M.create_commands()
  vim.api.nvim_create_user_command("UgatermOpen", function()
    terminal:open()
  end, {})
  vim.api.nvim_create_user_command("UgatermNew", function()
    terminal:new_open()
  end, {})
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
