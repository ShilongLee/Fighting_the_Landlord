local skynet = require "skynet"
local socket = require "skynet.socketdriver"
local gateserver = require "snax.gateserver"
local netpack = require "skynet.netpack"
local proto = require "pack_proto"
local sproto = require "sproto"
local error = require "error"
local command = require "gated.command"
local call = require "gated.call"
local gated = require "gated.gated"
local Log = require "logger"
require "skynet.manager"

local handler = {}
local host = sproto.new(proto.gatedmsg):host("package")

function handler.message(fd, msg, size)
    local data = netpack.tostring(msg, size)
    local _, _, args, response = host:dispatch(data)
    local res
    if args.type == "redirect" then
        res = skynet.call(gated.conn[fd].battle_service, "lua", "dispatch_client_pack", args.msg) -- 转发给battle
    else
        local _, func, args, response = host:dispatch(args.msg)
        local f = command[func]
        res = f(fd, args)
        res = response(res)
    end
    res = response({
        result = error.ok,
        msg = res
    })
    local pack = string.pack(">s2", res)
    socket.send(fd, pack)
end

function handler.connect(fd, addr)
    gateserver.openclient(fd)
    gated.conn[fd] = {}
    gated.conn[fd].addr = addr
    Log.echo(addr, fd, "connect gated")
end

function handler.disconnect(fd)
    Log.echo(gated.conn[fd].addr, fd, "disconnect gated")
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
