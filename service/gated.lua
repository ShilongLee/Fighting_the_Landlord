local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "skynet.netpack"
local proto = require "pack_proto"
local sproto = require "sproto"
local config = require "server_config"
require "skynet.manager"

local handler = {}
local host = sproto.new(proto.gatedmsg):host("package")
local conn = {}
local call = {}
local command = {}

local function echo(addr, fd, msg)
    print("ip:" .. addr .. " fd:" .. fd .. "\t" .. msg)
end

function call.bind(args)
    conn[args.fd] = args
    gateserver.openclient(args.fd)
    echo(args.addr, args.fd, "connect gated")
end

function handler.message(fd, msg, size)
    -- local data = netpack.tostring(msg, size)
    -- local _, packagename, args, response = host:dispatch(data)
    -- response_func[packagename] = response
    -- redirect(args.msgtype, args.msg, fd)
end

function handler.connect(fd, addr)
    gateserver.openclient(fd)
    echo(addr, fd, "connect gated")
end

function handler.disconnect(fd)
    -- skynet.call("GATED", "lua", "disconnect_from_battle", conn[fd])
    gateserver.closeclient(fd)
    print("disconnect gated")
end

function handler.error(fd, msg)
    print(fd .. "error:" .. msg)
end

function handler.open(source, conf)
    -- print("gateserver start...........")
    skynet.register("GATED")
end

function handler.command(func, source, ...)
    local f = call[func]
    local res
    res = f(...)
end

gateserver.start(handler)
