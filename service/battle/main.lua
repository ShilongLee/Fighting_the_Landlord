local skynet = require "skynet"
local BATTLE = require "battle"
local call = require "battle.call"
require "skynet.manager"

local battle

-- local function battle_end()
--     local res -- 游戏结果
--     skynet.call("GATED", "lua", "battle_end", res)
-- end

skynet.start(function()
    battle = BATTLE:new()
    skynet.dispatch("lua", function(session, source, func, ...)
        local f = call[func]
        if session then
            skynet.ret(skynet.pack(f(battle, ...))) -- 回应消息
        else
            f(battle, ...)
        end
    end)
    skynet.register("BATTLE")
end)
