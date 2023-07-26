local ugaterm = require("ugaterm")

describe("Test for init.lua", function()
  it("create_commands()", function()
    ugaterm.create_commands()
    -- `2` means full match with a command
    assert.equals(2, vim.fn.exists(":UgatermOpen"))
    assert.equals(2, vim.fn.exists(":UgatermHide"))
    assert.equals(2, vim.fn.exists(":UgatermSend"))
    assert.equals(2, vim.fn.exists(":UgatermRename"))
  end)
end)
