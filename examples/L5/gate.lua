local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "netpack"

local handler = {}
local connection = {}
local server = {}

function handler.message(fd,msg,size)
    local _server = server[fd]
    if _server then
        skynet.redirect(_server,"SERVER","client",msg)
    end
end

function handler.connect(fd,address)
    connection[fd] = address;
    gateserver.openclient(fd)
    server[fd] = skynet.newservice("server")
    skynet.call(server[fd],"lua","start",{fd,address})
end

function handler.disconnect(fd)
    print(fd.."disconnect")
end

function handler.error(fd)
    print(fd.."error")
end

gateserver.start(handler)