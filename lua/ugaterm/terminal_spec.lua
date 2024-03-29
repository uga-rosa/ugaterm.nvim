local lru = require("ugaterm.lru")
local terminal = require("ugaterm.terminal")

local function reset()
  terminal.prev_winid = nil
  terminal.term_winid = nil
  terminal.buf_cache = lru.new()
end

local function num_win()
  return vim.fn.winnr("$")
end

vim.opt.shell = "bash"

describe("Test for terminal", function()
  before_each(function()
    vim.cmd("silent %bwipeout!")
    reset()
  end)

  describe("open()", function()
    it("no flags", function()
      assert.equals(1, num_win())
      terminal:open({})
      assert.equals(2, num_win())
      -- Don't toggle
      terminal:open({})
      assert.equals(2, num_win())
    end)

    it("-new", function()
      assert.equals(1, num_win())
      terminal:open({ new = true })
      assert.equals(2, num_win())
      assert.equals("terminal://1", vim.api.nvim_buf_get_name(0))
      terminal:open({ new = true })
      assert.equals("terminal://2", vim.api.nvim_buf_get_name(0))
    end)

    it("-toggle", function()
      assert.equals(1, num_win())
      terminal:open({ toggle = true })
      assert.equals(2, num_win())
      terminal:open({ toggle = true })
      assert.equals(1, num_win())
    end)

    it("-select", function()
      -- Select the last item.
      -- The default vim.ui.select is not available for vusted.
      vim.ui.select = function(items, _, on_choice)
        local selected_item = items[#items]
        on_choice(selected_item)
      end

      assert.equals(1, num_win())
      terminal:open({})
      assert.equals(2, num_win())
      terminal:open({ new = true })
      assert.equals("terminal://2", vim.api.nvim_buf_get_name(0))
      terminal:open({ select = true })
      assert.equals("terminal://1", vim.api.nvim_buf_get_name(0))
    end)
  end)

  describe("hide()", function()
    it("no flags", function()
      assert.equals(1, num_win())
      terminal:open({})
      assert.equals(2, num_win())
      terminal:hide({})
      assert.equals(1, num_win())
      assert.equals(1, #terminal.buf_cache:get_all())
    end)

    it("-delete", function()
      assert.equals(1, num_win())
      terminal:open({})
      assert.equals(2, num_win())
      terminal:hide({ delete = true })
      assert.equals(1, num_win())
      assert.equals(0, #terminal.buf_cache:get_all())
    end)
  end)

  describe("send()", function()
    it("empty", function()
      terminal:open({})
      vim.wait(500, function() end)
      local old_lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
      terminal:send()
      terminal:send("")
      vim.wait(500, function() end)
      local new_lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
      assert.same(old_lines, new_lines)
    end)

    it("string", function()
      terminal:open({})
      vim.wait(500, function() end)
      local old_lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
      assert.falsy(table.concat(old_lines, "\n"):find("echo 'hi'\nhi"))
      terminal:send("echo 'hi'")
      vim.wait(500, function() end)
      local new_lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
      assert.truthy(table.concat(new_lines, "\n"):find("echo 'hi'\nhi"))
    end)

    it("string[]", function()
      terminal:open({})
      vim.wait(500, function() end)
      local old_lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
      assert.falsy(table.concat(old_lines, "\n"):find("echo 'foo'\nfoo"))
      terminal:send({ "echo 'foo'", "echo 'bar'" })
      vim.wait(500, function() end)
      local new_lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
      assert.truthy(table.concat(new_lines, "\n"):find("echo 'foo'\nfoo"))
      assert.truthy(table.concat(new_lines, "\n"):find("echo 'bar'\nbar"))
    end)
  end)

  describe("rename()", function()
    vim.ui.input = function(_, on_confirm)
      on_confirm("new name")
    end

    it("No arguments", function()
      terminal:open({})
      assert.equals("terminal://1", vim.api.nvim_buf_get_name(0))
      terminal:rename()
      local bufname = vim.api.nvim_buf_get_name(0)
      assert.truthy(bufname:find("new name$"))
    end)

    it("newname", function()
      terminal:open({})
      assert.equals("terminal://1", vim.api.nvim_buf_get_name(0))
      terminal:rename("newnewnew")
      local bufname = vim.api.nvim_buf_get_name(0)
      assert.truthy(bufname:find("newnewnew$"))
    end)
  end)
end)
