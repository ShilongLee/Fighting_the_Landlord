local skynet = require "skynet"
local socket = require "skynet.socketdriver"
local gateserver = require "snax.gateserver"
local netpack = require "skynet.netpack"
local proto = require "pack_proto"
local sproto = require "sproto"
local errorcode = require "error_code"
local command = require "gated.command"
local call = require "gated.call"
local gated = require "gated.gated"
require "skynet.manager"

local handler = {}
local host = sproto.new(proto.gatedmsg):host("package")

function handler.message(fd, msg, size)
    local data = netpack.tostring(msg, size)
    local _, _, args, response = host:dispatch(data)
    local res
    if args.type == "redirect" then
        res = skynet.redirect(gated.conn[fd].battle, gated.caddr[fd], "lua", args.msg) -- 转发给battle
    else
        local _, func, args, response = host:dispatch(args.msg)
        local f = command[func]
        res = f(fd, args)
        res = response(res)
    end
    res = response({
        result = errorcode.ok,
        msg = res
    })
    local pack = string.pack(">s2", res)
    socket.send(fd, pack)
    -- 战斗已经结束
end

function handler.connect(fd, addr)
    gateserver.openclient(fd)
    gated.caddr[fd] = addr
    gated.echo(addr, fd, "connect gated")
end

function handler.disconnect(fd)
    skynet.call("LOBBY", "lua", "disconnect_from_battle", gated.conn[fd].account)
    gated.echo(gated.caddr[fd], fd, "disconnect gated")
    gated.caddr[fd] = nil
    gated.conn[fd] = nil
    gateserver.closeclient(fd)
end

function handler.open(source, conf)
    skynet.register("GATED")
end

function handler.command(func, source, ...)
    local f = call[func]
    local res
    res = f(source, ...)
end

gateserver.start(handler)

-- battle_end
-- battle_response
