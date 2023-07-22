local config = require("ugaterm.config")
local terminal = require("ugaterm.terminal")

local M = {}

M.setup = config.set

---@class ParsedArgs
---@field [1] string[]
---@field boolean table<string, boolean?>
---@field string table<string, string?>

---@param fargs string[]
---@param options { boolean: string[], string: string[] }
---@return ParsedArgs
local function parse(fargs, options)
  ---@type ParsedArgs
  local parsedArgs = {
    [1] = {},
    boolean = {},
    string = {},
  }
  local i = 1
  while i <= #fargs do
    local arg = fargs[i]
    local flag = arg:sub(2)
    if vim.startswith(arg, "-") then
      if vim.list_contains(options.string or {}, flag) then
        i = i + 1
        parsedArgs.string[flag] = fargs[i]
      elseif vim.list_contains(options.boolean or {}, flag) then
        parsedArgs.boolean[flag] = true
      end
    else
      table.insert(parsedArgs[1], arg)
    end
    i = i + 1
  end
  return parsedArgs
end

---@return string[]
local function get_bufnames()
  return vim
    .iter(terminal.buf_cache:iter())
    :map(function(buf_cache)
      return buf_cache.bufname
    end)
    :totable()
end

function M.create_commands()
  vim.api.nvim_create_user_command("UgatermOpen", function(opt)
    local parsedArgs = parse(opt.fargs, {
      boolean = { "new", "toggle", "select" },
      string = { "name" },
    })
    local cmd
    if opt.range == 0 then
      cmd = table.concat(parsedArgs[1], " ")
    else
      cmd = vim.api.nvim_buf_get_lines(0, opt.line1 - 1, opt.line2, true) --[[@as string[] ]]
    end
    parsedArgs[1] = nil
    local name = parsedArgs.string.name
    terminal:open(parsedArgs.boolean, name, cmd)
  end, {
    nargs = "*",
    range = true,
    ---@param _ string
    ---@param cmdline string
    ---@param cursor_pos integer
    ---@return string[]
    complete = function(_, cmdline, cursor_pos)
      if cmdline:sub(1, cursor_pos):find("%-name%s+%S*$") then
        return get_bufnames()
      end
      local items = { "-new", "-toggle", "-select", "-name" }
      for i = #items, 1, -1 do
        if cmdline:find(items[i], 1, true) then
          table.remove(items, i)
        end
      end
      return items
    end,
  })

  vim.api.nvim_create_user_command("UgatermHide", function(opt)
    local parsedArgs = parse(opt.fargs, { boolean = { "delete" } })
    terminal:hide(parsedArgs.boolean)
  end, {
    nargs = "?",
    complete = function()
      return { "-delete" }
    end,
  })

  vim.api.nvim_create_user_command("UgatermSend", function(opt)
    local parsedArgs = parse(opt.fargs, { string = { "name" } })
    local cmd = table.concat(parsedArgs[1], " ")
    if cmd == "" then
      vim.notify("No command", vim.log.levels.ERROR)
    else
      terminal:send(cmd, parsedArgs.string.name)
    end
  end, {
    nargs = "+",
    ---@param _ string
    ---@param cmdline string
    ---@param cursor_pos integer
    ---@return string[]
    complete = function(_, cmdline, cursor_pos)
      if cmdline:sub(1, cursor_pos):find("%-name%s+%S*$") then
        return get_bufnames()
      end
      return { "-name" }
    end,
  })

  vim.api.nvim_create_user_command("UgatermRename", function(opt)
    local parsedArgs = parse(opt.fargs, { string = { "target" } })
    local newname = parsedArgs[1][1]
    terminal:rename(newname, parsedArgs.string.target)
  end, {
    nargs = "*",
    ---@param _ string
    ---@param cmdline string
    ---@param cursor_pos integer
    ---@return string[]
    complete = function(_, cmdline, cursor_pos)
      if cmdline:sub(1, cursor_pos):find("%-target%s+%S*$") then
        return get_bufnames()
      end
      return { "-target" }
    end,
  })
end

return M
