local list = {}

function list:new_node(key, value)
    return {
        key = key,
        value = value,
        pre = nil,
        next = nil
    }
end

function list:insert(key, value)
    local node = self:new_node(key, value)
    if not self.head then
        self.head = node
        self.tail = node
        return
    end
    self.tail.next = node
    node.pre = self.tail
    self.tail = node
    self.length = self.length + 1
    self.map[key] = node
end

function list:remove(key)
    if not self.map[key] then
        return
    end
    if self.head.key == key then
        self.head = self.head.next
    end
    if self.tail.key == key then
        self.tail = self.tail.pre
    end
    local node = self.map[key]
    if node.pre then
        node.pre.next = node.next
    end
    if node.next then
        node.next.pre = node.pre
    end
    self.map[key] = nil
    self.length = self.length - 1
end

function list:pop()
    if not self.head then
        return nil, nil
    end
    local key = self.head.key
    local value = self.head.value
    self.head = self.head.next
    self.length = self.length - 1
    self.map[key] = nil
    return key, value
end

function list:new()
    local t = {}
    setmetatable(t, {
        __index = self
    })
    t.length = 0
    t.map = {}
    t.head = nil
    t.tail = nil
    return t
end

return list
