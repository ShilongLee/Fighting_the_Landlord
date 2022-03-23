local skynet = require "skynet"
local sproto = require "sproto"
local proto = require "pack_proto"
local config = require "server_config"
local socket = require "skynet.socketdriver"
local host = sproto.new(proto.gatedmsg):host("package")
local pack_req = host:attach(sproto.new(proto.gatedmsg))
local gated = require "gated.gated"
local call = {}

function call.Reg(source, args)
    gated.Will_conn[args.token] = args
    skynet.timeout(1000, function()
        if gated.Will_conn[args.token] then
            skynet.call("LOBBY", "lua", "disconnect_from_battle", args.account)
        end
        gated.Will_conn[args.token] = nil
    end)
end

function call.battle_end(source,args)
    if gated.battle[source] then
        for _, fd in ipairs(gated.battle[source]) do
            -- notify_battle_end  连接lobby
            skynet.call("LOBBY", "lua", "battle_end", {
                account = gated.conn[fd].account,
                res = args
            })
            local msg = pack_req({
                token = gated.conn[fd].token,
                address = config.lobby_conf.address,
                port = config.lobby_conf.port
            })
            local pack = string.pack(">s2", msg)
            socket.send(fd, pack)
        end
    end
end

return call
