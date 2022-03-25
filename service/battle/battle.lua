local ROLE = require "battle.role"
local battle = {}

function battle:add_role(account)
    self.roles[account] = ROLE:new()
end

function battle:start()

end

function battle:new()
    local t = {}
    setmetatable(t, {
        __index = self
    })
    t.roles = {} -- account -> role
    return t
end

return battle
