local lru = require("ugaterm.lru")

---@class buf_cache
---@field name string
---@field id integer

---@class Terminal
---@field prefix string Terminal buffer name prefix
---@field filetype string Terminal filetype
---@field open_cmd string
---@field capacity integer
---@field buf_cache LruCache Keys are buffer names, values are buf_cache
---@field winid integer?
local Terminal = {
  prefix = "ugaterm",
  filetype = "ugaterm",
  open_cmd = "botright 15sp",
  capacity = 10,
}

---@return Terminal
function Terminal.new()
  return setmetatable({
    buf_cache = lru.new(Terminal.capacity),
  }, { __index = Terminal })
end

---@param opts table?
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
  vim.api.nvim_create_user_command("UgatermClose", function()
    terminal:close()
  end, {})
  vim.api.nvim_create_user_command("UgatermToggle", function()
    terminal:toggle()
  end, {})
  vim.api.nvim_create_user_command("UgatermSelect", function()
    terminal:select()
  end, {})
end

---@param id integer?
---@return boolean
local function winid_is_valid(id)
  return not not (id and vim.api.nvim_win_is_valid(id))
end

---@param id integer?
---@return boolean
local function bufid_is_valid(id)
  return not not (id and vim.api.nvim_buf_is_valid(id))
end

---Open a terminal window.
---@return boolean success true if it can be opened, otherwise false
function Terminal:_open()
  if winid_is_valid(self.winid) then
    return false
  end
  vim.cmd(self.open_cmd)
  self.winid = vim.api.nvim_get_current_win()
  return true
end

---Open a most recently used terminal or new one.
---If it's already open, exit immediately.
function Terminal:open()
  if not self:_open() then
    return
  end

  ---@type buf_cache?
  local buf_cache = self.buf_cache:get()
  if buf_cache and bufid_is_valid(buf_cache.id) then
    -- Open most recently used terminal
    vim.api.nvim_win_set_buf(self.winid, buf_cache.id)
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
  local bufid = vim.api.nvim_get_current_buf()
  local bufname = self.prefix .. (self.buf_cache:count() + 1)
  local buf_cache = { name = bufname, id = bufid }
  self.buf_cache:set(bufname, buf_cache)

  -- Set buffer name and options
  vim.api.nvim_buf_set_name(bufid, bufname)
  vim.api.nvim_buf_set_option(bufid, "buflisted", false)
  vim.api.nvim_buf_set_option(bufid, "filetype", self.filetype)

  vim.cmd.startinsert()
end

---Close a terminal window.
function Terminal:close()
  if winid_is_valid(self.winid) then
    vim.api.nvim_win_hide(self.winid)
  end
  self.winid = nil
end

---Toggle a terminal window.
function Terminal:toggle()
  if winid_is_valid(self.winid) then
    self:close()
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
    table.insert(bufnames, node.value.name)
    node = node.next
  end
  vim.ui.select(bufnames, {
    prompt = "Select terminals: ",
  }, function(choice)
    local buf_cache = self.buf_cache:get(choice)
    ---@cast buf_cache buf_cache
    self:_open()
    vim.api.nvim_win_set_buf(self.winid, buf_cache.id)
  end)
end

return Terminal
