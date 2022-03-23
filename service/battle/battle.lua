local skynet = require "skynet"
require "skynet.manager"

local function battle_end()
    local res   --游戏结果
    skynet.call("GATED", "lua", "battle_end",res)
end

skynet.start(function()
    -- skynet.dispatch("lua", function(session, source, msg)
    -- local _, _, args, response = host:dispatch(args.msg)
    -- if session then
    --     skynet.ret(skynet.pack(f(data_base, user_data, conn, Will_conn, ...))) -- 回应消息
    -- else
    --     f(data_base, user_data, conn, Will_conn, ...)
    -- end
    -- end)
    skynet.register("BATTLE")
end)
