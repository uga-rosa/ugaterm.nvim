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

  it("remove", function()
    cache:set(1, "a")
    cache:set(2, "b")
    assert.equals(2, cache:count())
    cache:remove(2)
    assert.equals(1, cache:count())
    assert.equals("a", cache:get())
  end)

  it("iter", function()
    cache:set(1, "a")
    cache:set(2, "b")
    local iter = cache:iter()
    assert.equals("b", iter())
    assert.equals("a", iter())
    assert.is_nil(iter())
  end)

  it("get_all", function()
    cache:set(1, "a")
    cache:set(2, "b")
    local caches = cache:get_all()
    assert.same({ "b", "a" }, caches)
  end)
end)
