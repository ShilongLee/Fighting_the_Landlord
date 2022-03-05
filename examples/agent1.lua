package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;practice/?.lua" -- ?
local skynet = require "skynet"
local socket = require "skynet.socket"
local proto = require "proto"
local sproto = require "sproto"
require "skynet.manager"

local REQUEST = {}

function REQUEST.say(tab)
    print("say", tab.name, tab.age)
end

function REQUEST.handshake()
    print("handshake")
end

function REQUEST.quit()
    print("quit")
end

local function request(func, args, response)
    local f = assert(REQUEST[func])
    local ret = f(args)
    if response then
        print("response")
    end
end

local function accept(fd)
    socket.start(fd)
    local host = sproto.new(proto.c2s):host("package")
    while true do
        local str = socket.read(fd)
        if str then
            local type, func, args, response = host:dispatch(str)
            if type == "REQUEST" then
                request(func, args, response)
                print("have recieved !")
            else
                print("response from client")
            end
        else
            socket.close(fd)
            return
        end
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, fd)
        skynet.fork(function()
            accept(fd)
        end)
        skynet.ret()
    end)
end)
