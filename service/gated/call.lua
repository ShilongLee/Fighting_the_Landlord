local skynet = require "skynet"
local sproto = require "sproto"
local proto = require "pack_proto"
local config = require "server_config"
local socket = require "skynet.socketdriver"
local host = sproto.new(proto.gatedmsg):host("package")
local pack_req = host:attach(sproto.new(proto.gatedmsg))
local gated = require "gated.gated"
local call = {}

function call.register(source, args)
    gated.Will_conn[args.token] = args.battle_service
    if not gated.battle[args.battle_service] then
        gated.battle[args.battle_service] = {}
    end
    local exist = false
    for _, token in ipairs(gated.battle[args.battle_service]) do
        if token == args.token then
            exist = true
            break
        end
    end
    if not exist then
        table.insert(gated.battle[args.battle_service], args.token)
    end
    skynet.timeout(1000, function()
        gated.Will_conn[args.token] = nil
    end)
end

function call.battle_end(source, args)
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
