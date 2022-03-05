package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;practice/?.lua" -- ?
local skynet = require "skynet"
local socket = require "skynet.socket"
local proto = require "proto"
local sproto = require "sproto"
local host = sproto.new(proto.c2s):host "package"
require "skynet.manager"

local fd = ...
fd = tonumber(fd)

local function func(fd)
    socket.start(fd)
    while true do
        local str = socket.read(fd)
        print(str)
        if str ~= nil and str ~= "" then
            if str == "quit" then
                socket.close(fd)
                break
            else
                print("client say:" .. str)
            end
        else
            socket.close(fd)
            return
        end
    end
end

skynet.start(function()
    skynet.fork(function()
        func(fd)
        skynet.exit()
    end)
end)
