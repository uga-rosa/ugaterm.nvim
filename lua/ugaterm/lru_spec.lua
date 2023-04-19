local lru = require("ugaterm.lru")

---@type LruCache
local cache

describe("Test for lru cache", function()
  before_each(function()
    cache = lru.new()
  end)

  it("get by key", function()
    cache:set(1, "a")
    assert.equals("a", cache:get(1))
  end)

  it("get without key (most recent used)", function()
    cache:set(1, "a")
    cache:set(2, "b")
    assert.equals("b", cache:get())
    cache:get(1)
    assert.equals("a", cache:get())
  end)

  it("shift", function()
    cache:set(1, "a")
    cache:set(2, "b")
    assert.equals("b", cache:shift())
    assert.equals("a", cache:shift())
    assert.equals(0, cache:count())
  end)
end)
