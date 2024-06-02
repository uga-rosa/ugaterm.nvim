local lru = require("ugaterm.lru")
local config = require("ugaterm.config")

---@class BufCache
---@field bufnr integer
---@field bufname string
---@field chan_id integer

---@class Terminal
---@field buf_cache LruCache Key is bufname, value is BufCache.
---@field term_winid? integer ID of the terminal window.
---@field prev_winid? integer ID of the window when the terminal window was opened.
local Terminal = {
  buf_cache = lru.new(),
}

---@param bufname? string
---@return BufCache?
function Terminal:get_cache(bufname)
  return self.buf_cache:get(bufname)
end

---@param winid? integer
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
function Terminal:open_win()
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

---@param bufname string
---@return boolean
local function bufexists(bufname)
  return vim.fn.bufexists(bufname) == 1
end

--- Open a most recently used terminal or new one.
--- If it's already open, exit immediately.
---@param flags { new: boolean?, toggle: boolean?, select: boolean?, keep_cursor: boolean? }
---@param name? string
---@param cmd? string | string[]
function Terminal:open(flags, name, cmd)
  ---@param buf_cache? BufCache
  local function cleanup(buf_cache)
    if not flags.new and buf_cache then
      -- Open the most recently used terminal.
      vim.api.nvim_win_set_buf(self.term_winid, buf_cache.bufnr)
    else
      -- Open a new terminal.
      name = name or config.get("prefix") .. (self.buf_cache:count() + 1)
      if bufexists(name) then
        vim.notify(("buffer '%s' is already exists"):format(name), vim.log.levels.ERROR)
        return
      end

      -- Create a cache
      local bufnr = vim.api.nvim_create_buf(false, false)
      vim.api.nvim_win_set_buf(self.term_winid, bufnr)
      ---@diagnostic disable-next-line:undefined-field
      local shell = vim.opt.shell:get()
      local chan_id = vim.fn.termopen(shell, vim.empty_dict())
      self.buf_cache:set(name, { bufnr = bufnr, bufname = name, chan_id = chan_id })

      vim.api.nvim_buf_set_name(bufnr, name)
      vim.api.nvim_set_option_value("filetype", config.get("filetype"), { buf = bufnr })
    end

    self:send(cmd)
    vim.cmd("do User UgatermEnter")
    if flags.keep_cursor then
      vim.schedule(function()
        vim.fn.win_gotoid(self.prev_winid)
      end)
    end
  end

  if flags.select then
    local buf_caches = self.buf_cache:get_all()
    if #buf_caches == 0 then
      vim.notify("No terminals", vim.log.levels.INFO)
      return
    end
    vim.ui.select(
      buf_caches,
      {
        prompt = "Select terminal: ",
        ---@param buf_cache BufCache
        format_item = function(buf_cache)
          return buf_cache.bufname
        end,
      },
      ---@param buf_cache? BufCache
      function(buf_cache)
        if buf_cache then
          self:open_win()
          cleanup(buf_cache)
        end
      end
    )
  else
    if self:open_win() or flags.new then
      local buf_cache = self:get_cache(name)
      cleanup(buf_cache)
    elseif flags.toggle then
      self:hide({})
    else
      self:send(cmd)
    end
  end
end

--- Hide a terminal window.
---@param flags { delete: boolean? }
function Terminal:hide(flags)
  if not self:is_opened() then
    return
  end
  vim.cmd("do User UgatermLeave")

  local in_term = vim.api.nvim_get_current_win() == self.term_winid
  if flags.delete then
    local bufnr = vim.api.nvim_win_get_buf(self.term_winid)
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    self.buf_cache:remove(buf_name)
    -- The terminal window close too.
    vim.api.nvim_buf_delete(bufnr, { force = true })
  else
    vim.api.nvim_win_hide(self.term_winid)
  end
  self.term_winid = nil
  if in_term then
    vim.fn.win_gotoid(self.prev_winid)
  end
end

---@param x? string | string[]
---@return boolean
local function is_empty(x)
  if type(x) == "table" then
    return table.concat(x, ""):find("^%s*$") ~= nil
  else
    return x == nil or x == ""
  end
end

---@param cmd? string | string[]
---@param bufname? string
function Terminal:send(cmd, bufname)
  if is_empty(cmd) then
    return
  end

  local buf_cache = self:get_cache(bufname)
  if buf_cache then
    cmd = type(cmd) == "table" and cmd or { cmd } --[[@as string[] ]]
    if cmd[#cmd] ~= "" then
      table.insert(cmd, "")
    end
    vim.fn.chansend(buf_cache.chan_id, cmd)
  end
end

--- Rename a current terminal buffer.
---@param newname? string
---@param target? string
function Terminal:rename(newname, target)
  local buf_cache = self:get_cache(target)
  if not (buf_cache and (target or self:is_opened())) then
    return
  end

  ---@param bufname? string
  local function cleanup(bufname)
    if not bufname or bufname == "" then
      return
    end
    if bufexists(bufname) then
      vim.notify(("Buffer '%s' is already exists"):format(bufname), vim.log.levels.ERROR)
    else
      vim.api.nvim_buf_set_name(buf_cache.bufnr, bufname)
      buf_cache.bufname = bufname
    end
  end

  if newname and newname ~= "" then
    cleanup(newname)
  else
    vim.ui.input({
      prompt = "Rename the terminal buffer: ",
      default = buf_cache.bufname,
    }, cleanup)
  end
end

return Terminal
