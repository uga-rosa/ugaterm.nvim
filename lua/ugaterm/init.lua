local lru = require("ugaterm.lru")

---@class Terminal
---@field prefix string Terminal buffer name prefix
---@field filetype string Terminal filetype
---@field open_cmd string|function
---@field buf_cache LruCache Keys are buffer names, values are buffer ids.
---@field winid integer|nil
local Terminal = {
  prefix = "ugaterm",
  filetype = "ugaterm",
  open_cmd = "botright 15sp",
}

---@return Terminal
function Terminal.new()
  return setmetatable({
    buf_cache = lru.new(),
  }, { __index = Terminal })
end

---@param opts table|nil
function Terminal.setup(opts)
  for k, v in pairs(opts or {}) do
    Terminal[k] = v
  end

  local terminal = Terminal.new()

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

---@param id integer|nil
---@return boolean
local function bufid_is_valid(id)
  return not not (id and vim.api.nvim_buf_is_valid(id))
end

---Return true if the terminal window is opened, else false.
---@return boolean
function Terminal:is_opened()
  if self.winid and vim.api.nvim_win_is_valid(self.winid) then
    return true
  else
    self.winid = nil
    return false
  end
end

---Open a terminal window.
---@return boolean success true if it can be opened, else false
function Terminal:_open()
  if self:is_opened() then
    return false
  end
  if type(self.open_cmd) == "string" then
    vim.cmd(self.open_cmd)
  else
    self.open_cmd()
  end
  self.winid = vim.api.nvim_get_current_win()
  return true
end

---Open a most recently used terminal or new one.
---If it's already open, exit immediately.
function Terminal:open()
  if not self:_open() then
    return
  end

  local bufid = self.buf_cache:get()
  if bufid_is_valid(bufid) then
    -- Open most recently used terminal
    vim.api.nvim_win_set_buf(self.winid, bufid)
    vim.cmd.startinsert()
  else
    -- Open new terminal
    self:new_open()
  end
end

---Open a new terminal.
function Terminal:new_open()
  self:_open()

  vim.cmd.terminal()

  -- Create a cache
  local bufname = self.prefix .. (self.buf_cache:count() + 1)
  local bufid = vim.api.nvim_get_current_buf()
  self.buf_cache:set(bufname, bufid)

  -- Set buffer name and options
  vim.api.nvim_buf_set_name(bufid, bufname)
  vim.api.nvim_buf_set_option(bufid, "buflisted", false)
  vim.api.nvim_buf_set_option(bufid, "filetype", self.filetype)

  vim.cmd.startinsert()
end

---Hide a terminal window.
function Terminal:hide()
  if self:is_opened() then
    vim.api.nvim_win_hide(self.winid)
  end
end

---Toggle a terminal window.
function Terminal:toggle()
  if self:is_opened() then
    self:hide()
  else
    self:open()
  end
end

---Select a terminal using vim.ui.select().
function Terminal:select()
  if self.buf_cache:count() == 0 then
    vim.notify("No terminals", vim.log.levels.WARN)
    return
  end
  local bufnames = {}
  local node = self.buf_cache.linked_list.head.next
  while node:is_valid() do
    table.insert(bufnames, node.key)
    node = node.next
  end
  vim.ui.select(bufnames, {
    prompt = "Select terminals: ",
  }, function(choice)
    local bufid = self.buf_cache:get(choice)
    self:_open()
    vim.api.nvim_win_set_buf(self.winid, bufid)
  end)
end

---Delete a current terminal buffer.
---If there are other terminals, open more recently used one.
---If this is the last one, close the window too.
function Terminal:delete()
  if not self:is_opened() then
    return
  end

  -- Delete a current terminal buffer
  local buf_cache = self.buf_cache:shift()
  if not (buf_cache and bufid_is_valid(buf_cache.id)) then
    return
  end
  -- The terminal window close too.
  vim.api.nvim_buf_delete(buf_cache.id, { force = true })
  self.winid = nil

  if self.buf_cache:count() > 0 then
    self:open()
  end
end

---Rename a current terminal buffer.
---@param newname string
function Terminal:rename(newname)
  if not self:is_opened() then
    return
  end
  local bufid = self.buf_cache:shift()
  if not bufid_is_valid(bufid) then
    return
  end

  if newname ~= "" then
    vim.api.nvim_buf_set_name(bufid, newname)
    self.buf_cache:set(newname, bufid)
    return
  end

  vim.ui.input(
    {
      prompt = "Rename a terminal buffer: ",
    },
    ---@param input string|nil
    function(input)
      if input then
        vim.api.nvim_buf_set_name(bufid, input)
        self.buf_cache:set(input, bufid)
      end
    end
  )
end

return Terminal
