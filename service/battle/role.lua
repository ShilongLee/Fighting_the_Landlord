local config = require "server_config"

local role = {}

function role:new()
    local t = {}
    setmetatable(t, {
        __index = self
    })
    t.token = nil
    t.hp = nil
    t.atk = nil
    t.def = nil
    t.career = nil
    return t
end

function role:change_hp(val)
    self.hp = self.hp + val
    -- notify
end

function role:change_atk(val)
    self.atk = self.atk + val
    -- notify
end

function role:change_def(val)
    self.def = self.def + val
    -- notify
end

return role
