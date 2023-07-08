local M = {}

---@class UgatermOptions
---@field prefix string Terminal buffer name prefix
---@field filetype string Terminal filetype
---@field open_cmd string|function The command/function to open a teminal window.

---@type UgatermOptions
local default = {
  prefix = "terminal://",
  filetype = "ugaterm",
  open_cmd = "botright 15sp",
}

M._option = default

---@param opts? UgatermOptions
function M.set(opts)
  opts = opts or {}
  vim.validate({
    opt = { opts, "t" },
    prefix = { opts.prefix, "s", true },
    filetype = { opts.prefix, "s", true },
    open_cmd = { opts.open_cmd, { "s", "c" }, true },
  })
  M._option = vim.tbl_extend("force", default, opts or {})
end

---@param key string
---@return string|function
function M.get(key)
  return M._option[key]
end

return M
