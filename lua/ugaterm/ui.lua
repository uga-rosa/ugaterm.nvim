local lru = require("ugaterm.lru")
local config = require("ugaterm.config")

---@class BufCache
---@field bufnr number
---@field bufname string

---@class UI
---@field buf_cache LruCache Key is bufnr, value is BufCache.
---@field term_winid integer|nil ID of the terminal window.
---@field prev_winid integer|nil ID of the window when the terminal window was opened.
local UI = {}

---@return UI
function UI.new()
  return setmetatable({
    buf_cache = lru.new(),
  }, { __index = UI })
end

---@param winid integer|nil
---@return boolean
local function win_is_valid(winid)
  return winid ~= nil and vim.api.nvim_win_is_valid(winid)
end

---Return true if the terminal window is opened, else false.
---@return boolean
function UI:is_opened()
  if win_is_valid(self.term_winid) then
    return true
  else
    self.term_winid = nil
    return false
  end
end

---Open a terminal window.
---@return boolean success true if it can be opened, else false
function UI:_open()
  if self:is_opened() then
    return false
  end
  self.prev_winid = vim.api.nvim_get_current_win()
  local open_cmd = config.get("open_cmd")
  if type(open_cmd) == "string" then
    vim.cmd(open_cmd)
  else
    open_cmd()
  end
  self.term_winid = vim.api.nvim_get_current_win()
  return true
end

---@param buf_cache BufCache|nil
---@return integer|nil bufnr
local function extract_bufnr(buf_cache)
  if buf_cache ~= nil and vim.api.nvim_buf_is_valid(buf_cache.bufnr) then
    return buf_cache.bufnr
  end
end

---Open a most recently used terminal or new one.
---If it's already open, exit immediately.
function UI:open()
  if not self:_open() then
    return
  end

  local bufnr = extract_bufnr(self.buf_cache:get())
  if bufnr then
    -- Open most recently used terminal
    vim.api.nvim_win_set_buf(self.term_winid, bufnr)
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
function UI:new_open(name)
  ---@param bufname? string
  local function cleanup(bufname)
    if bufname == nil or bufname == "" then
      return
    elseif bufexists(bufname) then
      vim.notify(("buffer '%s' is already exists"):format(bufname), vim.log.levels.ERROR)
      return
    end

    self:_open()
    vim.cmd.terminal()

    -- Create a cache
    local bufnr = vim.api.nvim_get_current_buf()
    self.buf_cache:set(bufnr, { bufnr = bufnr, bufname = bufname })

    -- Set buffer name and options
    vim.api.nvim_buf_set_name(bufnr, bufname)
    vim.api.nvim_set_option_value("buflisted", false, { buf = bufnr })
    vim.api.nvim_set_option_value("filetype", config.get("filetype"), { buf = bufnr })

    vim.cmd.startinsert()
  end

  -- Determine the buffer name
  local bufname = config.get("prefix") .. (self.buf_cache:count() + 1)
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
function UI:hide()
  if not self:is_opened() then
    return
  end
  local in_term = vim.api.nvim_get_current_win() == self.term_winid
  vim.api.nvim_win_hide(self.term_winid)
  self.term_winid = nil
  if in_term then
    vim.fn.win_gotoid(self.prev_winid)
  end
end

---Toggle a terminal window.
function UI:toggle()
  if self:is_opened() then
    self:hide()
  else
    self:open()
  end
end

---Select a terminal using vim.ui.select().
function UI:select()
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
function UI:delete()
  if not self:is_opened() then
    return
  end
  local bufnr = vim.api.nvim_win_get_buf(self.term_winid)
  self.buf_cache:remove(bufnr)

  local in_term = vim.api.nvim_get_current_win() == self.term_winid
  -- The terminal window close too.
  vim.api.nvim_buf_delete(bufnr, { force = true })
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
function UI:rename(newname)
  if not self:is_opened() then
    return
  end
  local bufnr = vim.api.nvim_win_get_buf(self.term_winid)

  ---@param bufname? string
  local function cleanup(bufname)
    if bufname == nil or bufname == "" then
      return
    elseif bufexists(bufname) then
      vim.notify(("buffer '%s' is already exists"):format(bufname), vim.log.levels.ERROR)
      return
    end
    vim.api.nvim_buf_set_name(bufnr, bufname)
    self.buf_cache:set(bufnr, { bufnr = bufnr, bufname = bufname })
  end

  if newname ~= "" then
    cleanup(newname)
  else
    vim.ui.input({
      prompt = "Rename a terminal buffer: ",
      default = vim.api.nvim_buf_get_name(bufnr),
    }, cleanup)
  end
end

return UI
