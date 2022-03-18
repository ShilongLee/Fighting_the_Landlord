local skynet = require "skynet"
-- local socket = require "skynet.socket"
local gateserver = require "snax.gateserver"
local netpack = require "skynet.netpack"
local proto = require "pack_proto"
local sproto = require "sproto"
local config = require "server_config"
local errorcode = require "error_code"
require "skynet.manager"

local handler = {}
local host = sproto.new(proto.gatedmsg):host("package")
local conn = {}
local Will_conn = {}
local call = {}
local command = {}
local caddr = {}

local function echo(addr, fd, msg)
    print("ip:" .. addr .. " fd:" .. fd .. "\t" .. msg)
end

function call.bind(args)
    Will_conn[args.token] = args
    skynet.timeout(1000, function()
        if Will_conn[args.token] then
            skynet.call("LOBBY", "lua", "disconnect_from_battle", args.account)
        end
        Will_conn[args.token] = nil
    end)
end

function handler.message(fd, msg, size)
    local data = netpack.tostring(msg, size)
    local _, func, args, response = host:dispatch(data)
    if args.type == "bind" then
        local _, _, args, response = host:dispatch(args.msg)
        conn[fd] = Will_conn[args.token]
        Will_conn[args.token] = nil
        echo(caddr[fd], fd, "bind success")
    end
    local res = response({
        result = errorcode.ok
    })
    return res  --没有回复
    -- response_func[packagename] = response
    -- redirect(args.msgtype, args.msg, fd)
end

function handler.connect(fd, addr)
    gateserver.openclient(fd)
    caddr[fd] = addr
    echo(addr, fd, "connect gated")
end

function handler.disconnect(fd)
    skynet.call("LOBBY", "lua", "disconnect_from_battle", conn[fd].account)
    gateserver.closeclient(fd)
    echo(caddr[fd], fd, "disconnect gated")
end

function handler.error(fd, msg)
    print(fd .. "error:" .. msg)
end

function handler.open(source, conf)
    skynet.register("GATED")
end

function handler.command(func, source, ...)
    local f = call[func]
    local res
    res = f(...)
end

gateserver.start(handler)
