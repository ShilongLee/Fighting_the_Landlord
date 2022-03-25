local proto = require "pack_proto"
local sproto = require "sproto"
local host = sproto.new(proto.battlemsg):host("package")
-- local pack_req = host:attach(sproto.new(proto.battlemsg))

local call = {}

function call.init_battle(battle, players_accounts)
    for _, account in ipairs(players_accounts) do
        battle:add_role(account)
    end
    return battle
end

function call.dispatch_client_pack(battle, msg)
    local _, func, args, response = host:dispatch(msg)
    print(func,args)
end

return call
