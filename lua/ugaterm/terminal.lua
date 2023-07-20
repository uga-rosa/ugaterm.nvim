local lru = require("ugaterm.lru")
local config = require("ugaterm.config")

---@class BufCache
---@field bufnr integer
---@field bufname string
---@field chan_id integer

---@class Terminal
---@field buf_cache LruCache Key is bufnr, value is BufCache.
---@field term_winid integer|nil ID of the terminal window.
---@field prev_winid integer|nil ID of the window when the terminal window was opened.
local Terminal = {}

---@return Terminal
function Terminal.new()
  return setmetatable({
    buf_cache = lru.new(),
  }, { __index = Terminal })
end

---@param winid integer|nil
---@return boolean
local function win_is_valid(winid)
  return winid ~= nil and vim.api.nvim_win_is_valid(winid)
end

--- Return true if the terminal window is opened, else false.
---@return boolean
function Terminal:is_opened()
  if win_is_valid(self.term_winid) then
    return true
  else
    self.term_winid = nil
    return false
  end
end

--- Open a terminal window.
---@return boolean success true if it can be opened, else false
function Terminal:_open()
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

---@param event string
local function send_event(event)
  vim.cmd("do User " .. event)
end

---@return BufCache | nil
function Terminal:get_cache()
  return self.buf_cache:get()
end

--- Open a most recently used terminal or new one.
--- If it's already open, exit immediately.
---@param cmd? string
function Terminal:open(cmd)
  if not self:_open() then
    return
  end

  local buf_cache = self:get_cache()
  if buf_cache then
    -- Open most recently used terminal
    vim.api.nvim_win_set_buf(self.term_winid, buf_cache.bufnr)
    if cmd and cmd ~= "" then
      self:send(cmd)
    end
    send_event("UgatermEnter")
  else
    -- Open new terminal
    self:new_open(cmd)
  end
end

---@param bufname string
---@return boolean
local function bufexists(bufname)
  return vim.fn.bufexists(bufname) == 1
end

--- Open a new terminal.
---@param cmd? string
function Terminal:new_open(cmd)
  local bufname = config.get("prefix") .. (self.buf_cache:count() + 1)
  if bufexists(bufname) then
    vim.notify(("buffer '%s' is already exists"):format(bufname), vim.log.levels.ERROR)
    return
  end

  self:_open()

  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_win_set_buf(self.term_winid, bufnr)
  local chan_id = vim.fn.termopen(vim.opt.shell:get(), vim.empty_dict())
  if cmd and cmd ~= "" then
    vim.fn.chansend(chan_id, { cmd, "" })
  end

  -- Create a cache
  self.buf_cache:set(bufnr, { bufnr = bufnr, bufname = bufname, chan_id = chan_id })

  -- Set buffer name and options
  vim.api.nvim_buf_set_name(bufnr, bufname)
  vim.api.nvim_set_option_value("buflisted", false, { buf = bufnr })
  vim.api.nvim_set_option_value("filetype", config.get("filetype"), { buf = bufnr })

  send_event("UgatermEnter")
end

---@param cmd string
function Terminal:send(cmd)
  local buf_cache = self.buf_cache:get()
  if buf_cache then
    vim.fn.chansend(buf_cache.chan_id, { cmd, "" })
  end
end

---@param bufname string
---@param cmd string
function Terminal:send_to(bufname, cmd)
  for buf_cache in self.buf_cache:iter() do
    ---@cast buf_cache BufCache
    if buf_cache.bufname == bufname then
      vim.fn.chansend(buf_cache.chan_id, { cmd, "" })
      return
    end
  end
end

--- Hide a terminal window.
function Terminal:hide()
  if not self:is_opened() then
    return
  end
  send_event("UgatermLeave")
  local in_term = vim.api.nvim_get_current_win() == self.term_winid
  vim.api.nvim_win_hide(self.term_winid)
  self.term_winid = nil
  if in_term then
    vim.fn.win_gotoid(self.prev_winid)
  end
end

--- Toggle a terminal window.
function Terminal:toggle()
  if self:is_opened() then
    self:hide()
  else
    self:open()
  end
end

--- Delete a current terminal buffer.
--- If there are other terminals, open more recently used one.
--- If this is the last one, close the window too.
function Terminal:delete()
  if not self:is_opened() then
    return
  end
  local bufnr = vim.api.nvim_win_get_buf(self.term_winid)
  self.buf_cache:remove(bufnr)

  if self.buf_cache:count() == 0 then
    send_event("UgatermLeave")
  end

  local in_term = vim.api.nvim_get_current_win() == self.term_winid
  -- The terminal window close too.
  vim.api.nvim_buf_delete(bufnr, { force = true })
  self.term_winid = nil
  if in_term then
    vim.fn.win_gotoid(self.prev_winid)
  end

  local buf_cache = self:get_cache()
  if buf_cache then
    self:_open()
    vim.api.nvim_win_set_buf(self.term_winid, buf_cache.bufnr)
  end
end

--- Select a terminal using vim.ui.select().
---@param bufname? string
function Terminal:select(bufname)
  if bufname and bufname ~= "" then
    for buf_cache in self.buf_cache:iter() do
      ---@cast buf_cache BufCache
      if buf_cache.bufname == bufname then
        if self:_open() then
          send_event("UgatermEnter")
        end
        vim.api.nvim_win_set_buf(self.term_winid, buf_cache.bufnr)
        return
      end
    end
    vim.notify("Invalid buffer name: " .. bufname, vim.log.levels.ERROR)
    return
  end

  if self.buf_cache:count() == 0 then
    vim.notify("No terminals", vim.log.levels.INFO)
    return
  end
  ---@type BufCache[]
  local buf_caches = {}
  for buf_cache in self.buf_cache:iter() do
    table.insert(buf_caches, buf_cache)
  end
  vim.ui.select(
    buf_caches,
    {
      prompt = "Select terminals: ",
      ---@param buf_cache BufCache
      ---@return string
      format_item = function(buf_cache)
        return buf_cache.bufname
      end,
    },
    ---@param buf_cache BufCache | nil
    function(buf_cache)
      if buf_cache == nil then
        -- Canceled
        return
      end
      if self:_open() then
        send_event("UgatermEnter")
      end
      vim.api.nvim_win_set_buf(self.term_winid, buf_cache.bufnr)
    end
  )
end

--- Rename a current terminal buffer.
---@param newname string
function Terminal:rename(newname)
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

return Terminal
