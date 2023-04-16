---@class CacheNode
---@field key unknown
---@field value unknown
---@field prev CacheNode
---@field next CacheNode
local CacheNode = {
  _dummy = {},
}

---@param key unknown
---@param value unknown? If nil, use self._dummy
---@return CacheNode
function CacheNode.new(key, value)
  local self = setmetatable({}, { __index = CacheNode })
  self.key = key
  if value ~= nil then
    self.value = value
  else
    self.value = self._dummy
  end
  return self
end

---Return false if node is dummy, otherwise true.
---@return boolean
function CacheNode:is_valid()
  return self.value ~= self._dummy
end

---@class LinkedList
---@field head CacheNode
---@field tail CacheNode
local LinkedList = {}

---@return LinkedList
function LinkedList.new()
  local self = setmetatable({}, { __index = LinkedList })
  self.head = CacheNode.new(0) -- dummy
  self.tail = CacheNode.new(0) -- dummy
  self.head.next = self.tail
  self.tail.prev = self.head
  return self
end

---@param node CacheNode
function LinkedList:add(node)
  node.prev = self.head
  node.next = self.head.next
  self.head.next = node
  node.next.prev = node
end

---@param node CacheNode
function LinkedList:remove(node)
  node.prev.next = node.next
  node.next.prev = node.prev
end

---@param node CacheNode
function LinkedList:move2head(node)
  self:remove(node)
  self:add(node)
end

---@class LruCache
---@field capacity integer
---@field key2node table<unknown, CacheNode>
---@field linked_list LinkedList
local LruCache = {}

---@param capacity integer
---@return LruCache
function LruCache.new(capacity)
  local self = setmetatable({}, { __index = LruCache })
  self.capacity = capacity
  self.key2node = {}
  self.linked_list = LinkedList.new()
  return self
end

---@param key unknown
---@param value unknown
function LruCache:set(key, value)
  if self.key2node[key] then
    local node = self.key2node[key]
    node.value = value
    self.linked_list:move2head(node)
  else
    local new_node = CacheNode.new(key, value)
    self.key2node[key] = new_node
    self.linked_list:add(new_node)

    if vim.tbl_count(self.key2node) > self.capacity then
      local final_node = self.linked_list.tail.prev
      self.key2node[final_node.key] = nil
      self.linked_list:remove(final_node)
    end
  end
end

---If key is omitted, return the most recently used data.
---@param key unknown?
---@return unknown?
function LruCache:get(key)
  if key ~= nil then
    local node = self.key2node[key]
    if node then
      self.linked_list:move2head(node)
      return node.value
    end
  else
    if vim.tbl_count(self.key2node) > 0 then
      local node = self.linked_list.head.next
      return node.value
    end
  end
end

---@return integer
function LruCache:count()
  return vim.tbl_count(self.key2node)
end

return LruCache
