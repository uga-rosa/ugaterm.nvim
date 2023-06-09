local function num_win()
  return vim.fn.winnr("$")
end

---@type Terminal
local terminal

describe("Test for terminal", function()
  before_each(function()
    vim.cmd("silent %bwipeout!")
    terminal = require("ugaterm.terminal").new()
  end)

  it("open/hide", function()
    assert.equals(1, num_win())
    terminal:open()
    assert.equals(2, num_win())
    terminal:hide()
    assert.equals(1, num_win())
  end)

  it("toggle", function()
    assert.equals(1, num_win())
    terminal:toggle()
    assert.equals(2, num_win())
    terminal:toggle()
    assert.equals(1, num_win())
  end)

  it("new_open", function()
    terminal:open()
    assert.equals("terminal://1", vim.api.nvim_buf_get_name(0))
    terminal:new_open()
    assert.equals("terminal://2", vim.api.nvim_buf_get_name(0))
    terminal:hide()
  end)

  it("delete", function()
    terminal:open()
    assert.equals("terminal://1", vim.api.nvim_buf_get_name(0))
    terminal:new_open()
    assert.equals("terminal://2", vim.api.nvim_buf_get_name(0))
    terminal:delete()
    assert.equals("terminal://1", vim.api.nvim_buf_get_name(0))
    terminal:hide()
  end)

  describe("return to the original window", function()
    ---@param callback fun(orig_winid: integer)
    local function assert_keep_win(callback)
      local orig_winid = vim.api.nvim_get_current_win()
      callback(orig_winid)
      assert.equals(orig_winid, vim.api.nvim_get_current_win())
    end

    it("hide", function()
      assert_keep_win(function(orig_winid)
        vim.cmd.vsplit()
        vim.fn.win_gotoid(orig_winid)
        terminal:open()
        terminal:hide()
      end)
    end)

    it("delete", function()
      assert_keep_win(function(orig_winid)
        vim.cmd.vsplit()
        vim.fn.win_gotoid(orig_winid)
        terminal:open()
        terminal:new_open()
        terminal:delete()
        terminal:delete()
      end)
    end)

    describe("keep the position if outside the terminal", function()
      it("hide", function()
        assert_keep_win(function(orig_winid)
          vim.cmd.vsplit()
          terminal:open()
          vim.fn.win_gotoid(orig_winid)
          terminal:hide()
        end)
      end)

      it("delete", function()
        assert_keep_win(function(orig_winid)
          vim.cmd.vsplit()
          terminal:open()
          vim.fn.win_gotoid(orig_winid)
          terminal:delete()
        end)
      end)
    end)
  end)
end)
