local skynet = require "skynet"
local socket = require "skynet.socket"
local proto = require "proto"
local sproto = require "sproto"
local host = sproto.new(proto.app):host(package)
local function accept(fd)
    socket.start(fd)


end

skynet.start(function()
    local listenfd = socket.listen("127.0.0.1", 6666)
    socket.start(listenfd, function(fd, address)
        skynet.fork(function ()
            accept(fd)
        end)
    end)
end)
