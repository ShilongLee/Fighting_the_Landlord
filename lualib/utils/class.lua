local function class(className, super)
    local cls = { __cname = className, super = super }
    if super then
        setmetatable(cls, { __index = super })
    end
    cls.new = function(...)
        local obj = {}
        setmetatable(obj, { __index = cls })
        if obj._init then
            obj:_init(...)
        end
        return obj
    end
    return cls
end

return class