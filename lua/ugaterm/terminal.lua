local lru = require("ugaterm.lru")

---@class TerminalOptions
---@field prefix string Terminal buffer name prefix
---@field filetype string Terminal filetype
---@field open_cmd string|function The command/function to open a teminal window.

---@class Terminal
---@field options TerminalOptions
---@field buf_cache LruCache Keys are buffer names, values are buffer ids.
---@field term_winid integer|nil ID of the terminal window.
---@field prev_winid integer|nil ID of the original window where the terminal window was opened.
local Terminal = {
  options = {
    prefix = "terminal://",
    filetype = "ugaterm",
    open_cmd = "botright 15sp",
  },
}

---@return Terminal
function Terminal.new()
  return setmetatable({
    buf_cache = lru.new(),
  }, { __index = Terminal })
end

---@param opts TerminalOptions
function Terminal:option_set(opts)
  self.options = vim.tbl_extend("force", self.options, opts)
end

---@param id integer|nil
---@return boolean
local function bufid_is_valid(id)
  return not not (id and vim.api.nvim_buf_is_valid(id))
end

---Return true if the terminal window is opened, else false.
---@return boolean
function Terminal:is_opened()
  if self.term_winid and vim.api.nvim_win_is_valid(self.term_winid) then
    return true
  else
    self.term_winid = nil
    return false
  end
end

---Open a terminal window.
---@return boolean success true if it can be opened, else false
function Terminal:_open()
  if self:is_opened() then
    return false
  end
  self.prev_winid = vim.api.nvim_get_current_win()
  local open_cmd = self.options.open_cmd
  if type(open_cmd) == "string" then
    vim.cmd(open_cmd)
  else
    open_cmd()
  end
  self.term_winid = vim.api.nvim_get_current_win()
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
    vim.api.nvim_win_set_buf(self.term_winid, bufid)
    vim.cmd.startinsert()
  else
    -- Open new terminal
    self:new_open()
  end
end

---@param bufname string
---@return boolean
local function bufexists(bufname)
  return vim.fn.bufexists(bufname) == 1
end

---Open a new terminal.
---If {name} is given, it should be used as the buffer name.
---If {name} is an empty string, vim.ui.input() is called.
---@param name? string
function Terminal:new_open(name)
  ---@param bufname? string
  local function cleanup(bufname)
    if bufname == nil or bufname == "" then
      return
    elseif bufexists(bufname) then
      vim.notify(("buffer '%s' is already exists"):format(bufname))
      return
    end

    self:_open()
    vim.cmd.terminal()

    -- Create a cache
    local bufid = vim.api.nvim_get_current_buf()
    self.buf_cache:set(bufname, bufid)

    -- Set buffer name and options
    vim.api.nvim_buf_set_name(bufid, bufname)
    vim.api.nvim_buf_set_option(bufid, "buflisted", false)
    vim.api.nvim_buf_set_option(bufid, "filetype", self.options.filetype)

    vim.cmd.startinsert()
  end

  -- Determine the buffer name
  local bufname = self.options.prefix .. (self.buf_cache:count() + 1)
  if name == nil or name ~= "" then
    cleanup(name or bufname)
  else
    vim.ui.input({
      prompt = "Input the buffer name: ",
      default = bufname,
    }, cleanup)
  end
end

---Hide a terminal window.
function Terminal:hide()
  if self:is_opened() then
    local in_term = vim.api.nvim_get_current_win() == self.term_winid
    vim.api.nvim_win_hide(self.term_winid)
    self.term_winid = nil
    if in_term then
      vim.fn.win_gotoid(self.prev_winid)
    end
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
    vim.api.nvim_win_set_buf(self.term_winid, bufid)
  end)
end

---Delete a current terminal buffer.
---If there are other terminals, open more recently used one.
---If this is the last one, close the window too.
function Terminal:delete()
  if not self:is_opened() then
    return
  end

  local bufid = self.buf_cache:shift()
  if not bufid_is_valid(bufid) then
    return
  end

  local in_term = vim.api.nvim_get_current_win() == self.term_winid
  -- The terminal window close too.
  vim.api.nvim_buf_delete(bufid, { force = true })
  self.term_winid = nil
  if in_term then
    vim.fn.win_gotoid(self.prev_winid)
  end

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

  ---@param bufname? string
  local function cleanup(bufname)
    if bufname == nil or bufname == "" then
      return
    elseif bufexists(bufname) then
      vim.notify(("buffer '%s' is already exists"):format(bufname))
      return
    end
    vim.api.nvim_buf_set_name(bufid, bufname)
    self.buf_cache:set(bufname, bufid)
  end

  if newname ~= "" then
    cleanup(newname)
  else
    vim.ui.input({
      prompt = "Rename a terminal buffer: ",
      default = vim.api.nvim_buf_get_name(bufid),
    }, cleanup)
  end
end

return Terminal
